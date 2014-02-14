require 'openssl'
require 'Base64'
require 'cgi'

class QC
  def QC.hmac key, data
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha256'), key, data)
    b64_hmac = Base64.encode64(hmac).strip
    url_b64_hmac = CGI.escape(b64_hmac)
  end
end
