require 'openssl'
require 'Base64'
require 'cgi'
require 'json'
require 'net/http'

module QC
  QC::CERT_FILE = File.open(File.join(File.dirname(__FILE__), "qingcloud.com.cert.pem")).readlines.join

  def QC.hmac key, data
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, data)
    b64_hmac = Base64.encode64(hmac).strip
    url_b64_hmac = CGI.escape(b64_hmac)
  end

  module API
    class Request
      attr_reader :response

      def initialize access_key_id, action, extra_params = []
        @response = :not_requested

        @params = []
        @params << ['action', action]
        @params << ['access_key_id', access_key_id]
        @params << ['signature_method', 'HmacSHA256']
        @params << ['signature_version', 1]
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
            raise 'Hostname in certifcate is invalid!i (MITM?)' 
          end

          # Verify the individual certificate
          unless https.peer_cert.to_s == QC::CERT_FILE
            raise "Certificate isn't trustworthy!"
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
