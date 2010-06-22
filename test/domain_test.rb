require 'test/unit'
require 'cerealizer'

class DomainTest < Test::Unit::TestCase
  include Cerealizer

  def test_tmp
  end

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

  def test_join_finite_same_size
    a = Domain.finite_disjunction([:a,:b])
    b = Domain.finite_disjunction([:c,:d])
    c = Domain.join(a,b)
    assert_range(c, [:a,:b,:c,:d])
    assert_domain(c)
  end

  def test_join_finite_different_size
    a = Domain.finite_disjunction([:a,:b])
    b = Domain.finite_disjunction([:c,:d, :hh])
    c = Domain.join(a,b)
    assert_range(c, [:a,:b,:c,:d,:hh])
    assert_domain(c)
  end

  def test_join_infinite
    c = Domain.join(Domain::NATURAL_ARRAY, Domain::NATURAL_SET)
    a = [[], [1],[5,],[1,4,3],[2942],[2932,24,1],[75,9821389189]]
    assert_range(c, a + a.map{|aa|Set.new(aa)})
    assert_domain(c)
  end

  def test_join_both
    a = Domain.finite_disjunction([:yamaha, :kawasaki])
    b = Domain::NATURAL_SET
    c = Domain.join(a,b)
    assert_range(c, [:yamaha, :kawasaki, Set.new, Set.new([1,2]), Set.new([823])])
    assert_domain(c)
  end

  def test_join
    a = Domain.finite_disjunction("a".."z")
    b = Domain.finite_disjunction(10055..100255)
    c = Domain::NATURAL_SET
    combo = Domain.join(a,b,c)
    assert_domain(combo)
  end

  def test_recur_basic_tree
    leaf = Domain::NATURALS
    tree = (Domain.recursively_define do |ob|
      ob.define(:tree, Domain.join(leaf, Domain.cartesian_product(ob.stub(:tree),ob.stub(:tree))))
    end)[:tree]
    assert_domain(tree)
    assert_range(tree,[1,2,3,4,5,[1,[2,[3,4]]],[5,6],[6,7],[8,10],[[[6,3],8],[1,2]]])
    assert_not_range(tree, [[1,2,3], [1,[2,[6,3],[5]]]])
  end

  def test_set_of
    ascii_strings = Domain.set_of(Domain::ASCII)
    assert_domain(ascii_strings)
    assert_range(ascii_strings, [%w(this a nd that), %w(wait till they take), %w(down), %w(the), []].map{|a|Set.new(a)})
    assert_not_range(ascii_strings, ["A string", 3, Set.new(["this","and",12])])
  end

  private
  def assert_domain(d)
    ceiling = d.cardinality
    ceiling = 10**50 if ceiling == :aleph_null
    ([100,ceiling].min).times do |i|
      n = rand(ceiling) + 1
      unless(i+1 > ceiling)
        begin
          ob = d.from_n(i+1)
          nn = d.to_n(ob)
          assert_equal(i+1, nn, "Input #{i+1} maps to #{ob.inspect} and back to #{nn}")
        rescue(Exception) => e
          assert(false,"Exception thrown when trying to map from #{i+1}: #{e.inspect}")
        end
      end
      begin
        ob = d.from_n(n)
        nn = d.to_n(ob)
        assert_equal(n, nn, "Input #{n} maps to #{ob.inspect} and back to #{nn}")
      rescue(Exception) => e
        assert(false,"Exception thrown when trying to map from #{i+1}: #{e.inspect}")
      end
    end
  end

  def assert_range(d,r)
    r.each do |ob|
      n = d.to_n(ob)
      ob2 = d.from_n(n)
      assert_equal(ob, ob2, "Object #{ob.inspect} maps to #{n} and back to #{ob2.inspect}")
    end
  end

  def assert_not_range(d,r)
    r.each do |ob|
      assert_raises(CerealizerException) do
        d.to_n(r)
      end
    end
  end
end
