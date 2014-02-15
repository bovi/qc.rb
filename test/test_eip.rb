require 'test/unit'
require 'qc'

class QcTest < Test::Unit::TestCase
=begin
  def test_create_delete
    ret = QC::Eip.allocate bandwidth: 2
    assert_not_equal false, ret, "Should create one IP"

    ret = QC::Eip.release eips: ret
    assert_not_equal false, ret, "Should delete #{ret}"
  end
=end
end
