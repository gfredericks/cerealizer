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

      def self.string_partitions(string_length, n)
        return 1 if string_length == 0 or n == 1
        return n if string_length == 1
        @@sp||={}
        @@sp[[string_length,n]]||=begin
          (0..string_length).map{|x|string_partitions(string_length - x, n - 1)}.inject(0){|u,v|u+v}
        end
      end

      def self.nth_partition(s, n, i)
        raise "Foul!" if i > string_partitions(s.length, n)
        return [s] if n == 1
        return [""] * n if s.empty?
        last_length = 0
        while(i > (k=string_partitions(s.length-last_length, n-1)))
          last_length += 1
          i -= k
        end
        a = nth_partition(last_length == 0 ? s : s[0...(-last_length)], n-1, i)
        a << (last_length == 0 ? "" : s[(-last_length)..-1])
        a
      end

      def self.partition_lengths_to_n(a)
        return 1 if a.length < 2
        n = 0
        total = a.inject{|u,v|u+v}
        (0...a.last).each{|x|n+=string_partitions(total-x, a.length-1)}
        n + partition_lengths_to_n(a[0...-1])
      end

      binary_strings = Domain.string("01")
      Domain.new(
        lambda{|a|a.class == Array and a.length == length and a.all?{|n|is_n?(n)}},
        lambda{|a|
          a = a.map{|n|n.to_s(2)[1..-1]}
          total_bits = a.join("").length
          bits = 0
          n = 0
          while(bits < total_bits)
            n += (string_partitions(bits, length)*(2**bits))
            bits += 1
          end
          n += (a.join("").to_i(2))*string_partitions(total_bits, length)
          n + partition_lengths_to_n(a.map{|s|s.length})
        },
        lambda{|n|
          nn = 1
          bits = 0
          while(n > (k=string_partitions(bits, length)*(2**bits)))
            n -= k
            bits += 1
          end
          #nn = binary_strings.to_n("0"*bits)
          k = string_partitions(bits, length)
          n-=1
          #nn += n/k
          s = "%0#{bits}d" % ((n/k).to_s(2).to_i)
          s = "" if bits == 0
          n = 1 + n % k

          parts = nth_partition(s, length, n)
          parts.map{|s|("1"+s).to_i(2)}
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
  end
end
