require 'test/unit'
require 'cerealizer'

class BinaryTest < Test::Unit::TestCase
  def test_basic
    b = Binary.new
    %w(this that and the other thing).each do |string|
      assert_serializes(b, string)
    end
  end

  private
  def assert_serializes(serializer, ob)
    assert_equal(ob, serializer.from_n(serializer.to_n(ob)))
  end
end
