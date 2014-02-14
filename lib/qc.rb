require 'openssl'
require 'Base64'
require 'cgi'
require 'json'
require 'net/http'

module QC
  QC::CA_FILE = ca_file = File.join(File.dirname(__FILE__), "qingcloud.com.cert.pem")

  def QC.hmac key, data
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, data)
    b64_hmac = Base64.encode64(hmac).strip
    url_b64_hmac = CGI.escape(b64_hmac)
  end

  module API
    class Request
      attr_reader :response

      def initialize action, key, access_key_id
        @response = :not_requested

        @params = []
        @params << ['action', action]
        @params << ['access_key_id', access_key_id]
      end

      def execute!(key)
        @uri = URI.parse(API.json2url(key, @params.to_json))
        https = Net::HTTP.new(@uri.host, 443)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        #https.ca_file = QC::CA_FILE
        @response = https.request(Net::HTTP::Get.new(@uri.request_uri))
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
