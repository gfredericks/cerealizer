require 'set'

module Cerealizer
  class Domain
    attr_accessor :cardinality

    private 
    def initialize(domain, to_n, from_n, cardinality)
      @domain=domain
      @to_n=to_n
      @from_n=from_n
      @cardinality=cardinality
    end

    public

    def self.string(alphabet)
      alphabet = alphabet.split("") if(alphabet.class == String)
      check_that("Alphabet must consist of single-character strings") do
        alphabet.all? do |char|
          char.class == String and char.length == 1
        end
      end
      alphabet = alphabet.uniq
      alphabet_set = Set.new(alphabet)
      Domain.new(
        lambda{|ob|ob.class == String and ob.split("").all?{|c|alphabet_set.include?(c)}},
        lambda{|s|
          possible = 1
          digits = 0
          n = 1
          until(digits == s.length)
            n += possible
            digits += 1
            possible *= alphabet.length
          end
          mult = 1
          i = s.length-1
          while(i >= 0)
            n += mult*alphabet.index(s[i..i])
            mult *= alphabet.length
            i-=1
          end
          n
        },
        lambda{|n|
          return "" if n==1
          n-=1
          digits = 1
          possible = alphabet.length
          while(n > possible)
            n -= possible
            possible *=alphabet.length
            digits += 1
          end
          n-=1
          s = ""
          while(n > 0)
            s = alphabet[n % alphabet.length] + s
            n /= alphabet.length
          end
          alphabet[0]*(digits - s.length) + s
        },
        :aleph_null)
    end

    def self.fixed_length_natural_array(length)
      if(length==0)
        return Domain.new(lambda{|el|el==[]},
                          lambda{|a|return 1},
                          lambda{|n|return []},
                          1)
      end

      Domain.new(
        lambda{|a|a.class == Array and a.length == length and a.all?{|n|is_n?(n)}},
        lambda{|a|
          t = a.inject{|u,v|u+v}
          n = cubico(length, t - 1)
          while(a.length>1)
            t-=a.shift
            n+=Tuple.cubico(a.length,t-1)
          end
          n},
        lambda{|n|
          total = length
          total +=1 until(cubico(length, total) >= n)
          n-=cubico(length, total - 1)
          helper(total, length, n)
        },
        :aleph_null)
    end

    def self.finite_disjunction(set)
      check_that("set must be enumerable"){set.class < Enumerable}
      set = set.to_set
      a = set.to_a
      Domain.new(
        lambda{|ob|set.include?(ob)},
        lambda{|el|1 + a.index?(el)},
        lambda{|n|a[n-1]},
        a.length)
    end

    def cartesian_product(*domains)
      check_that("arguments must all be domains"){domains.all?{|d|d.class == Domain}}
      check_that("at least one domain is required"){not domains.empty?}
    end

    def convert_to(ob, domain)
      domain.from_n(self.to_n(ob))
    end

    def to_n(el)
      Domain.check_that("Argument must be in domain"){@domain.call(el)}
      @to_n.call(el)
    end

    def from_n(n)
      Domain.check_that("Argument must be a natural number"){Domain.is_n?(n)}
      Domain.check_that("Argument must be within cardinality of domain") do
        @cardinality == :aleph_null or n <= @cardinality
      end
      @from_n.call(n)
    end
    
    private
    def self.is_n?(ob)
      [Fixnum, Bignum].include?(ob.class) and ob > 0
    end

    def self.check_that(message)
      raise message unless yield
    end

    public 

    require 'cerealizer/base_domains'

    include Cerealizer::BaseDomains

    private

    def fact(n)
      @@facts||=[1]
      @@facts.push(@@facts.length*@@facts.last) while(@@facts.length <=n)
      @@facts[n]
    end

    # Total number of tuples of length 'c' with total 't'
    def bico(c,t)
      return 0 if c > t
      (([t-c,c-1].max+1)..(t-1)).inject(1){|u,v|u*v}/fact([t-c,c-1].min)
    end
   
    # Total number of tuples of length 'c' with total <= 't'
    def cubico(c,t)
      return 0 if c > t
      bico(c+1,t+1)
    end

    # total, length, offset
    def helper(t,l,o)
      return [t] if l==1
      ret=Array.new(l)
      (0...(l-2)).each do |i|

        # Check for TakingTooLong
        raise TakingTooLongException if(Time.new - @started > @too_long)

        # This is where we should be able to use a binary search
        total_range=(l-i-1)..(t-1)
        # Need to find the smallest number j such that o < Tuple.cubico(l-i-1,j)
        until total_range.first==total_range.last
          guess=(total_range.first+total_range.last)/2
          if(o < Tuple.cubico(l-i-1,guess))
            total_range=total_range.first..(guess)
          else
            total_range=(guess+1)..total_range.last
          end
        end
        head=t-total_range.first
        o-=Tuple.cubico(l-i-1,total_range.first-1)

        ret[i]=head
        t-=head
      end
      ret[l-2]=t-o-1
      ret[l-1]=o+1
      ret
    end

  end
end
