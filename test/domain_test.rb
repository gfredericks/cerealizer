require 'test/unit'
require 'cerealizer'

class DomainTest < Test::Unit::TestCase
  include Cerealizer

  def test_base_domains
    assert_domain(Domain::NATURALS)
    assert_domain(Domain::ASCII)
    assert_domain(Domain::NATURAL_ARRAY)
    assert_domain(Domain::NATURAL_SET)
  end

  def test_finite_disjunction
    d = Domain.finite_disjunction((7..50).to_a)
    assert_domain(d)
  end

  def test_cartesian_product
    boolean = Domain.finite_disjunction([true,false])
    combo = Domain.cartesian_product(boolean, Domain::NATURALS)
    assert_domain(combo)
  end

  def test_join
    a = Domain.finite_disjunction("a".."z")
    b = Domain.finite_disjunction(10055..100255)
    c = Domain::NATURAL_SET
    combo = Domain.join(a,b,c)
    assert_domain(combo)
  end

  private
  def assert_domain(d)
    ceiling = d.cardinality
    ceiling = 10**50 if ceiling == :aleph_null
    100.times do |i|
      n = rand(ceiling) + 1
      assert_equal(i+1, d.to_n(d.from_n(i+1))) unless i+1 > ceiling
      assert_equal(n, d.to_n(d.from_n(n)))
    end
  end
end
