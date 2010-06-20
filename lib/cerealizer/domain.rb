require 'set'

module Cerealizer
  class Domain
    attr_accessor :cardinality, :domain

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

    def self.recursively_define
      ob = Object.new
      class << ob
        @domains = {}
        def define(domain_name)
          raise "Can only define one domain at a time" if(@defining)
          Domain.check_that("domain name must be symbol"){domain_name.class==Symbol}
          @defining = domain_name
          d = yield
          @defining = nil
          @domains[domain_name]=d
        end
        DOMAIN_COMBINATORS = %w(join cartesian_product)
        def method_missing(m, *args)
          super unless(Domain.respond_to?(m) and not Class.respond_to?(m))
          super unless(@defining)
          Domain.send(m, *args) unless DOMAIN_COMBINATORS.include?(m,to_s)
          args = args.map do |a|
            if(a.class == Symbol)
              Domain.new(lambda{|x|@domains[a].domain.call(x)},
                         lambda{|x|@domains[a].to_n(x)},
                         lambda{|n|@domains[a].from_n(x)},
                         # THIS IS A QUESTIONABLE ASSUMPTION
                         :aleph_null)
            elsif(a.class == Domain)
              a
            end
          end
        end
      end
      yield(ob)
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
      a = set.to_a.uniq
      set = a.to_set
      Domain.new(
        lambda{|ob|set.include?(ob)},
        lambda{|el|1 + a.index(el)},
        lambda{|n|a[n-1]},
        a.length)
    end

    def self.join(*domains)
      check_that("arguments must all be domains"){domains.all?{|d|d.class == Domain}}
      check_that("at least two domains are required"){domains.length > 1}
      cards = domains.map{|d|d.cardinality}
      min = cards.reject{|c|c == :aleph_null}.min
      zipped = domains.zip((1..domains.length).to_a)
      card = (cards.uniq == [:aleph_null] ? :aleph_null : cards.length * min)
      spread_even=Domain.new(lambda{|a|(domains).any?{|d|d.domain.call(a)}},
                 lambda{|ob|
                   doms = zipped.select{|d,i|d.domain.call(ob)}
                   check_that("object must be part of exactly one domain"){doms.length == 1}
                   dom,i = doms[0]
                   (dom.to_n(ob) - 1)*domains.length + i
                 },
                 lambda{|n|
                   n-=1
                   domains[n % domains.length].from_n(1+n/domains.length)
                 },
                 card)
      if(min and cards.uniq.length > 1)
        chomped = domains.reject{|d|d.cardinality == min}.map{|d|d.drop(min)}
        dd = (chomped.length == 1 ? chomped[0] : Domain.join(*chomped))
        ceiling = min * cards.length
        Domain.new(spread_even.domain,
                   lambda{|ob|
                     n = spread_even.to_n(ob)
                     return n if n <= ceiling
                     ceiling + dd.to_n(ob)
                   },
                   lambda{|n|
                     if(n > ceiling)
                       dd.from_n(n-ceiling)
                     else
                       spread_even.from_n(n)
                     end
                   },
                   cards.any?{|c|c == :aleph_null} ? :aleph_null : cards.inject{|u,v|u+v})
      else
        spread_even
      end
    end

    def self.cartesian_product(*domains)
      check_that("arguments must all be domains"){domains.all?{|d|d.class == Domain}}
      check_that("at least two domains are required"){domains.length > 1}
      finites = []
      infinites = []
      domains.length.times do |i|
        if(domains[i].cardinality == :aleph_null)
          infinites << i
        else
          finites << i
        end
      end
      unless(infinites.empty?)
        infinite_domains = infinites.map{|i|domains[i]}
        ns = Domain.fixed_length_natural_array(infinites.length)
        infinite = Domain.new(lambda{|a|a.length == infinites.length and a.zip(infinite_domains).all?{|el,d|d.domain.call(el)}},
                              lambda{|a|
                                a = a.zip(infinite_domains).map{|el,d|d.to_n(el)}
                                ns.to_n(a)
                              },
                              lambda{|n|
                                a = ns.from_n(n)
                                a.zip(infinite_domains).map{|n,d|d.from_n(n)}
                              },
                              :aleph_null)
      end
      unless(finites.empty?)
        finite_domains = finites.map{|i|domains[i]}
        cards = finite_domains.map{|d|d.cardinality}
        total_card = cards.inject{|u,v|u*v}
        finite = Domain.new(lambda{|a|a.length == finites.length and a.zip(finite_domains).all?{|el,d|d.domain.call(el)}},
                            lambda{|a|
                              a = a.zip(finite_domains).map{|el,d|d.to_n(el)}
                              n = 1
                              mult = 1
                              a.zip(cards).each do |m, card|
                                n += (m-1)*mult
                                mult *= card
                              end
                              n
                            },
                            lambda{|n|
                              mult = total_card
                              a = finite_domains
                              n -= 1
                              a.map do |d|
                                nn = 1 + n%d.cardinality
                                n /= d.cardinality
                                d.from_n(nn)
                              end
                            },
                            total_card)
      end
      return finite if infinites.empty?
      return infinite if finites.empty?
      Domain.new(lambda{|a|a.length == domains.length and a.zip(domains).all?{|el,d|d.domain.call(el)}},
                 lambda{|a|
                   finite_n = finite.to_n(finites.map{|i|a[i]})
                   infinite_n = infinite.to_n(infinites.map{|i|a[i]})
                   (infinite_n-1)*total_card + finite_n
                 },
                 lambda{|n|
                   finite_n = 1 + (n-1)%total_card
                   infinite_n = 1 + (n-1)/total_card
                   fin_obs = finites.zip(finite.from_n(finite_n))
                   inf_obs = infinites.zip(infinite.from_n(infinite_n))
                   (inf_obs + fin_obs).sort_by{|a,b|a}.map{|a,b|b}
                 },
                 :aleph_null)
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

    # Returns a new domain that excludes the first n elements of this domain
    def drop(n)
      return self if n == 0
      Domain.check_that("Cannot drop more elements than exist") do
        @cardinality == :aleph_null or
        n <= @cardinality
      end
      Domain.check_that("Cannot drop all the elements of a domain") do
        @cardinality == :aleph_null or
        n < @cardinality
      end
      Domain.new(lambda{|ob|@domain.call(ob) and @to_n.call(ob) > n},
                 lambda{|ob|@to_n.call(ob) - n},
                 lambda{|m|@from_n.call(m + n)},
                 @cardinality == :aleph_null ? :aleph_null : @cardinality - n)
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
