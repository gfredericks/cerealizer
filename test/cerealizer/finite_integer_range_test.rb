require 'test/unit'
require 'cerealizer'

class FiniteIntegerRangeTest < Test::Unit::TestCase
  def test_range
    assert_raises(Cerealizer::CerealizerException) do
      FiniteIntegerRange.new("okay")
    end
  end
end
