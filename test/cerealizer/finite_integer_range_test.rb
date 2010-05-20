require 'test/unit'
require 'cerealizer'

class FiniteIntegerRangeTest < Test::Unit::TestCase
  def test_range
    f = FiniteIntegerRange.new(7..42)
    (7..42).each{|i|assert_equal(i, f.from_n(f.to_n(i)))}
    assert_raises(Cerealizer::BadDomainException) do
      f.to_n(6)
    end
    assert_raises(Cerealizer::BadDomainException) do
      f.to_n(43)
    end
  end
end
