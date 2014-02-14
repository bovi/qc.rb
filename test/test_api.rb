require 'test/unit'
require 'qc'

class QcTest < Test::Unit::TestCase
  def test_api_param_sort
    json_unsort = <<JSON.strip
[["count", 1], ["vxnets.1", "vxnet-0"], ["zone", "pek1"], ["instance_type", "small_b"], ["signature_version", 1], ["signature_method", "HmacSHA256"], ["instance_name", "demo"], ["image_id", "precisesrvx64"], ["version", 1], ["access_key_id", "QYACCESSKEYIDEXAMPLE"], ["action", "RunInstances"], ["time_stamp", "2013-08-27T14:30:10Z"]]
JSON
    json_sort = <<JSON.strip
[["access_key_id", "QYACCESSKEYIDEXAMPLE"], ["action", "RunInstances"], ["count", 1], ["image_id", "precisesrvx64"], ["instance_name", "demo"], ["instance_type", "small_b"], ["signature_method", "HmacSHA256"], ["signature_version", 1], ["time_stamp", "2013-08-27T14:30:10Z"], ["version", 1], ["vxnets.1", "vxnet-0"], ["zone", "pek1"]]
JSON
    assert_equal json_sort, QC::API::sort_json(json_unsort)
  end

  def test_api_param_req_str
    json = <<JSON.strip
[["access_key_id", "QYACCESSKEYIDEXAMPLE"], ["action", "RunInstances"], ["count", 1], ["image_id", "precisesrvx64"], ["instance_name", "demo"], ["instance_type", "small_b"], ["signature_method", "HmacSHA256"], ["signature_version", 1], ["time_stamp", "2013-08-27T14:30:10Z"], ["version", 1], ["vxnets.1", "vxnet-0"], ["zone", "pek1"]]
JSON
    api_req_str = <<REQ_STR.strip
GET\n/iaas/\naccess_key_id=QYACCESSKEYIDEXAMPLE&action=RunInstances&count=1&image_id=precisesrvx64&instance_name=demo&instance_type=small_b&signature_method=HmacSHA256&signature_version=1&time_stamp=2013-08-27T14%3A30%3A10Z&version=1&vxnets.1=vxnet-0&zone=pek1
REQ_STR
    assert_equal api_req_str, QC::API::json2reqstr(json)
  end

  def test_api_param_sign
    api_req_str = <<REQ_STR.strip
GET\n/iaas/\naccess_key_id=QYACCESSKEYIDEXAMPLE&action=RunInstances&count=1&image_id=precisesrvx64&instance_name=demo&instance_type=small_b&signature_method=HmacSHA256&signature_version=1&time_stamp=2013-08-27T14%3A30%3A10Z&version=1&vxnets.1=vxnet-0&zone=pek1
REQ_STR
    signature = 'jWp0Ul9j7xlKrTMNUZy16Ull7IS2lHV4IYUqB%2Bp7qFw%3D'
    assert_equal signature, QC::hmac('your_secret_key', api_req_str)
  end

  def test_api_param_json_sign
    json_unsort = <<JSON.strip
[["count", 1], ["vxnets.1", "vxnet-0"], ["zone", "pek1"], ["instance_type", "small_b"], ["signature_version", 1], ["signature_method", "HmacSHA256"], ["instance_name", "demo"], ["image_id", "precisesrvx64"], ["version", 1], ["access_key_id", "QYACCESSKEYIDEXAMPLE"], ["action", "RunInstances"], ["time_stamp", "2013-08-27T14:30:10Z"]]
JSON
    signature = 'jWp0Ul9j7xlKrTMNUZy16Ull7IS2lHV4IYUqB%2Bp7qFw%3D'
    assert_equal signature, QC::API::json2sign('your_secret_key', json_unsort)
  end

  def test_api_param
    json = <<JSON.strip
[["access_key_id", "QYACCESSKEYIDEXAMPLE"], ["action", "RunInstances"], ["count", 1], ["image_id", "precisesrvx64"], ["instance_name", "demo"], ["instance_type", "small_b"], ["signature_method", "HmacSHA256"], ["signature_version", 1], ["time_stamp", "2013-08-27T14:30:10Z"], ["version", 1], ["vxnets.1", "vxnet-0"], ["zone", "pek1"]]
JSON
    req_url = <<URL.strip
https://api.qingcloud.com/iaas/?access_key_id=QYACCESSKEYIDEXAMPLE&action=RunInstances&count=1&image_id=precisesrvx64&instance_name=demo&instance_type=small_b&signature_method=HmacSHA256&signature_version=1&time_stamp=2013-08-27T14%3A30%3A10Z&version=1&vxnets.1=vxnet-0&zone=pek1&signature=jWp0Ul9j7xlKrTMNUZy16Ull7IS2lHV4IYUqB%2Bp7qFw%3D
URL
    assert_equal req_url, QC::API::json2url('your_secret_key', json)
  end
end
