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

  class SSH
    def initialize s
      @id = s['keypair_id']
      @name = s['keypair_name']
      @date = s['create_time']
      @e_method = s['encrypt_method']
      @desc = s['description']
      @key = s['pub_key']
    end

    def to_s
      <<STR
ID:                "#{@id}"
Name:              "#{@name}"
Creation Date:     "#{@date}"
Encryption Method: "#{@e_method}"
Description:       "#{@desc}"
Public Key:
"#{@key}"
STR
    end

    def SSH.each &block
      r = QC::API::Request.new 'DescribeKeyPairs'
      r.execute!(QC::Key)['keypair_set'].to_a.each {|s| block.call(SSH.new(s))}
    end
  end

  class Instance
    def initialize s
      @id = s['instance_id']
      @name = s['instance_name']
      @type = s['instance_type']
      @vcpu = s['vcpu_current']
      @desc = s['description']
      @status = s['status']
    end

    def to_s
      <<STR
ID:                "#{@id}"
Name:              "#{@name}"
Type:              "#{@type}"
VCPU:              "#{@vcpu}"
Description:       "#{@desc}"
Status:            "#{@status}"
STR
    end

    def Instance.each &block
      r = QC::API::Request.new 'DescribeInstances'
      r.execute!(QC::Key)['instance_set'].to_a.each {|s| block.call(Instance.new(s))}
    end
  end

  module API
    class Request
      attr_reader :response

      def initialize action, extra_params = []
        @response = :not_requested

        @params = []
        @params << ['action', action]
        @params << ['access_key_id', QC::AccessKeyId]
        @params << ['signature_method', 'HmacSHA256']
        @params << ['signature_version', 1]
        @params << ['zone', QC::Zone]
        extra_params.each {|i| @params << i}
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
