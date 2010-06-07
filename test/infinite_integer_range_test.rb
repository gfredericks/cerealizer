require 'test/unit'
require 'cerealizer'

class InfiniteIntegerRangeTest < Test::Unit::TestCase
  def test_open_left
    ol = InfiniteIntegerRange.open_left(8)
    (-10..8).each{|i|assert_equal(i, ol.from_n(ol.to_n(i)))}
  end
  def test_open_right
    ol = InfiniteIntegerRange.open_right(8)
    (8..20).each{|i|assert_equal(i, ol.from_n(ol.to_n(i)))}
  end
  def test_open_both
    ol = InfiniteIntegerRange.open_both
    (-10..8).each{|i|assert_equal(i, ol.from_n(ol.to_n(i)))}
  end
end
