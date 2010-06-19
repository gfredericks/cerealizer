require 'test/unit'
require 'cerealizer'

class DomainTest < Test::Unit::TestCase

  def test_base_domains
    assert_domain(Cerealizer::Domain::NATURALS)
    assert_domain(Cerealizer::Domain::ASCII)
  end

  private
  def assert_domain(d)
    ceiling = d.cardinality
    ceiling = 10**50 if ceiling == :aleph_null
    1000.times do |i|
      n = rand(ceiling)
      assert_equal(i+1, d.to_n(d.from_n(i+1)))
      assert_equal(n, d.to_n(d.from_n(n)))
    end
  end
end
