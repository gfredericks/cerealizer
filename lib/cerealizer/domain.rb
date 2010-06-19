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

    NATURALS = Domain.new(
      lambda{|ob|self.is_n?(ob)},
      lambda{|x|x}, 
      lambda{|x|x},
      :aleph_null)

    ASCII = self.string(" !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")

    NATURAL_ARRAY = 
      begin
        ternary = self.string("012")
        split_twos = lambda do |s|
          i = s.index('2')
          return [s] unless i
          [s[0...i]] + split_twos.call(s[(i+1)..-1])
        end
        Domain.new(
          lambda{|a|a.class == Array and a.all?{|el|is_n?(el)}},
          lambda{|a|return 1 if a == []; 1 + ternary.to_n(a.map{|x|x.to_s(2)[1..-1]}.join("2"))},
          lambda{|n|return [] if n == 1; split_twos.call(ternary.from_n(n-1)).map{|x|("1"+x).to_i(2)}},
          :aleph_null)
      end

    NATURAL_SET = Domain.new(
      lambda{|ob|ob.class == Set and ob.all?{|el|is_n?(el)}},
      lambda{|s|
        a = s.to_a.sort
        i = a.length-1
        while(i > 0)
          a[i] = a[i] - a[i-1]
          i-=1
        end
        NATURAL_ARRAY.to_n(a)
      },
      lambda{|n|
        a = NATURAL_ARRAY.from_n(n)
        s = Set.new
        n = 0
        a.each do |m|
          s.add(n+=m)
        end
        s
      },
      :aleph_null)
  end
end
