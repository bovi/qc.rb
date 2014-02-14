require 'test/unit'
require 'qc'

class QcTest < Test::Unit::TestCase
  def test_hmac
    assert_equal 'q0YUxUpyT3Eli03MwOHDagk8szsTkbuw2%2FvdxzTb4b4%3D', 
                 QC.hmac('your_secret_key', 'string_to_sign')
  end
end
