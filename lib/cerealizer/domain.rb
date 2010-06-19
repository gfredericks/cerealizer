require 'set'

module Cerealizer
  class Domain
    NATURALS = Domain.new(
      lambda{|ob|self.is_n?(ob)},
      lambda{|x|x}, 
      lambda{|x|x},
      :aleph_null)

    def self.finite_disjunction(set)
      set = set.to_set
      a = set.to_a
      Domain.new(
        lambda{|ob|set.include?(ob)},
        lambda{|el|1 + a.index?(el)},
        lambda{|n|a[n-1]},
        a.length)
    end

    def convert_to(ob, domain)
      domain.from_n(self.to_n(ob))
    end

    def to_n(el)
      raise "Argument not in domain" unless @domain.include?(el)
      @to_n.call(el)
    end

    def from_n(n)
      raise "That's not a natural number" unless is_n?(n)
      raise "#{n} is larger than the cardinality of #{@cardinality}" unless
        @cardinality == :aleph_null or n <= @cardinality
      @from_n.call(n)
    end
    
    private
    def initialize(domain, to_n, from_n, cardinality)
      @domain=domain
      @to_n=to_n
      @from_n=from_n
      @cardinality=cardinality
    end

    def self.is_n?(ob)
      [Fixnum, Bignum].include?(ob.class) and ob > 0
    end
  end
end
