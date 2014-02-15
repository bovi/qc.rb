require 'test/unit'
require 'qc'

class QcTest < Test::Unit::TestCase
  def test_keypair
    QC::KeyPair.describe {|s| s}
  end
end
