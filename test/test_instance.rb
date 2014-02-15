require 'test/unit'
require 'qc'

class QcTest < Test::Unit::TestCase
  def test_instance
    QC::Instance.describe {|i| i}
  end
end
