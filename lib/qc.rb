require 'openssl'
require 'Base64'
require 'cgi'
require 'json'
require 'net/http'
require 'yaml'
require 'fileutils'

module QC
  VERSION = '0.0.1'

  def QC.load_config key
    f = File.expand_path('~/.qingcloud/config.yaml')
    if File.exists? f
      config = YAML.load(File.open(f))
      if config.has_key? key
        config[key]
      else
        raise "'#{key}' is missing in configuration file"
      end
    else
      puts "'#{f}' doesn't exist!"
      print "Do you want to create it? (Y/n)"
      a = $stdin.gets.strip
      if a == 'n'
        puts "No configuration file!"
        exit
      elsif a.downcase == 'y' or a == ''
        h = {}
        print 'Secret Key:'
        h['qy_secret_access_key'] = $stdin.gets.strip
        print 'Access Key ID:'
        h['qy_access_key_id'] = $stdin.gets.strip
        print 'Zone:'
        h['zone'] = $stdin.gets.strip
        begin
          FileUtils.mkdir_p(File.dirname(f))
          File.new(f, 'w+').puts YAML.dump(h)
          puts "Configuration file was created!"
        rescue Exception => e
          raise "Configuration file couldn't be created! (#{e.class}: #{e.message})"
        end
        exit
      end
    end
  end

  QC::CERT_FILE = File.open(File.join(File.dirname(__FILE__), "qingcloud.com.cert.pem")).readlines.join
  QC::Key = QC.load_config('qy_secret_access_key')
  QC::AccessKeyId = QC.load_config('qy_access_key_id')
  QC::Zone = QC.load_config('zone')

  def QC.hmac key, data
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, data)
    b64_hmac = Base64.encode64(hmac).strip
    url_b64_hmac = CGI.escape(b64_hmac)
  end

  class DataType
    attr_reader :result

    @identifier = 'NOT_IMPLEMENTED'

    def initialize h
      @values = h
    end

    def to_s
      @values.to_yaml
    end

    def method_missing met
      if @values.has_key? met.to_s
        @values[met.to_s]
      else
        raise NoMethodError.new "undefined method `#{met}'"
      end
    end

    def self.describe p = {}, &block
      req = QC::API::Request.new "Describe#{@identifier}s", p
      @result = req.execute!(QC::Key)
      if block_given?
        @result["#{@identifier.downcase}_set"].to_a.each {|s| block.call(self.new(s))}
      else
        @result["#{@identifier.downcase}_set"].to_a.map {|s| self.new(s)}
      end
    end
  end

  class KeyPair < DataType
    @identifier = 'KeyPair'
  end

  class Instance < DataType
    @identifier = 'Instance'

    def Instance.run p = {image_id: 'precisex64a', instance_name: nil, count: 1, login_mode: 'keypair',
                          login_keypair: nil, login_passwd: nil, security_group: nil, zone: nil, instance_type: 'small_b'}
      p[:image_id] = 'precisex64a' if p[:image_id].nil?
      p[:login_mode] = 'keypair' if p[:login_mode].nil?
      p[:instance_type] = 'small_b' if p[:instance_type].nil?
      p['vxnets.1'] = 'vxnet-0' if p['vxnets.1'].nil?
      ret = API::Request.execute! 'RunInstances', p
      ret['instances']
    end

    def Instance.load instance_id
      Instance.describe('instances.1' => instance_id)[0]
    end

    def terminate!
      p = {'instances.1' => @values['instance_id']}
      API::Request.execute!('TerminateInstances', p)
    end

    def ip= eip_id
      p = {'instance' => @values['instance_id'], 'eip' => eip_id}
      API::Request.execute!('AssociateEip', p)
    end
  end

  class Volume < DataType
    @identifier = 'Volume'
  end

  class Eip < DataType
    @identifier = 'Eip'

    def Eip.allocate p = {bandwidth: 1, eip_name: nil, count: 1, need_icp: nil, zone: nil}
      ret = API::Request.execute! 'AllocateEips', p
      if ret.respond_to? :has_key?
        ret['eips']
      else
        false
      end
    end

    def Eip.release eips: [], zone: nil
      if eips.size > 0
        p = {}
        1.upto(eips.size).each { |i| p["eips.#{i}"] = eips[i-1] }
        p[:zone] = zone
        API::Request.execute!('ReleaseEips', p)
      else
        false
      end
    end

    def Eip.load eip_id
      Eip.describe('eips.1' => eip_id)[0]
    end

    def bandwidth= b
      p = {'eips.1' => @values['eip_id'], 'bandwidth' => b}
      ret = API::Request.execute!('ChangeEipsBandwidth', p)
      if ret.respond_to? :has_key?
        b
      else
        false
      end
    end

    def release!
      p = {'eips.1' => @values['eip_id']}
      API::Request.execute!('ReleaseEips', p)
    end
  end

  class Image < DataType
    include Comparable
    @identifier = 'Image'

    def Image.describe p = {}, &block
      _p = p.dup
      unless _p.has_key? 'provider'
        _p['provider'] = 'system'
      end
      super _p, &block
    end

    def to_s
      [@values['image_id'], @values['image_name']].to_yaml
    end

    def <=> o
      @values['image_id'] <=> o.image_id
    end
  end

  module API
    class Request
      attr_reader :response

      def Request.execute! a, p = {}
        req = QC::API::Request.new a, p
        @result = req.execute!(QC::Key)
        if @result['ret_code'] == 0
          @result
        else
          raise ArgumentError.new("#{@result['ret_code']}: #{@result['message']}")
        end
      end

      def initialize action, extra_params = {}
        @response = :not_requested

        @params = []
        @params << ['action', action]
        @params << ['access_key_id', QC::AccessKeyId]
        @params << ['signature_method', 'HmacSHA256']
        @params << ['signature_version', 1]
        zone_set = false
        extra_params.each_pair do |k,v|
          zone_set = true if k == 'zone'
          next if v.nil?
          @params << [k.to_s, v]
        end
        @params << ['zone', QC::Zone] unless zone_set
      end

      def execute!(key)
        _p = @params.dup
        _p << ['time_stamp', Time.now.utc.strftime("%FT%TZ")]
        @uri = URI.parse(API.json2url(key, _p.to_json))

        # Establish a SSL connection
        Net::HTTP.start(@uri.host, 443,
                        :use_ssl => true,
                        :verify_mode  => OpenSSL::SSL::VERIFY_PEER) do |https|

          # Verify additional the host name in the certificate to avoid MITM
          unless OpenSSL::SSL.verify_certificate_identity(https.peer_cert, 'qingcloud.com')
            raise 'Hostname in certifcate does NOT match! (MITM?)' 
          end

          # Verify the individual certificate
          unless https.peer_cert.to_s == QC::CERT_FILE
            raise "Certificate is NOT trustworthy!"
          end

          ####################################################################
          # Starting from this point I consider the SSL connection as safe!

          @response = https.request(Net::HTTP::Get.new(@uri.request_uri))

          # After this point we close the SSL connection.
          ####################################################################
        end

        JSON.parse(@response.body)
      end
    end

    def API.sort_json json
      JSON.parse(json).to_a.sort.to_s
    end

    def API.json2reqstr json
      "GET\n/iaas/\n" + json2params(json)
    end

    def API.json2sign key, json
      QC.hmac(key, json2reqstr(sort_json(json)))
    end

    def API.json2url key, json
      sign = json2sign(key, json)
      params = json2params(json)
      "https://api.qingcloud.com/iaas/?#{params}&signature=#{sign}"
    end

    private

    def API.json2params json
      JSON.parse(json).to_a.map do |i|
        "#{CGI.escape(i[0])}=#{CGI.escape(i[1].to_s)}"
      end.join('&')
    end
  end
end
