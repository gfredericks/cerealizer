require 'set'
require 'cerealizer/cerealizer_exception'

module Cerealizer
  module FixedLengthArrayMethods
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
  end

  class Domain
    attr_accessor :cardinality, :domain

    ARRAY_TO_SET = lambda {|a|
        s = Set.new
        n = 0
        a.each do |m|
          s.add(n+=m)
        end
        s
      }
    SET_TO_ARRAY = lambda {|s|
        a = s.to_a.sort
        i = a.length-1
        while(i > 0)
          a[i] = a[i] - a[i-1]
          i-=1
        end
        a
      }

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
        attr_reader :domains # is this necessary??
        def define(domain_name, domain)
          @domains ||= {}
          Domain.check_that("domain name must be symbol"){domain_name.class==Symbol}
          Domain.check_that("domain must be a domain"){domain.class <= Domain}
          @domains[domain_name]=domain
        end

        def stub(domain_name)
          Domain.check_that("domain name must be symbol"){domain_name.class==Symbol}
          @domain_stubs||={}
          @domain_stubs[domain_name] ||= 
            Domain.new(lambda{|x|@domains[domain_name].domain.call(x)},
                       lambda{|x|@domains[domain_name].to_n(x)},
                       lambda{|n|@domains[domain_name].from_n(n)},
                       # THIS IS A QUESTIONABLE ASSUMPTION, maybe.
                       :aleph_null)
        end
      end
      yield(ob)
      ob.domains
    end

    def without(*obs)
      return self if obs.empty?
      Domain.check_that("All objects must be part of domain"){obs.all?{|ob|self.domain.call(ob)}}
      ob_set = Set.new(obs)
      mappings = obs.map{|ob|{ob=>self.to_n(ob)}}.inject{|u,v|u.merge(v)}
      indexes = mappings.values.sort
      Domain.new(lambda{|ob|self.domain.call(ob) and not ob_set.include?(ob)},
                 lambda{|ob|
                   n = self.to_n(ob)
                   n - indexes.select{|nn| n > nn}.length
                 },
                 lambda{|n|
                   i = 0
                   while(i < obs.length and n >= indexes[i])
                     i+=1
                     n+=1
                   end
                   self.from_n(n)
                 },
                 self.cardinality == :aleph_null ? :aleph_null : self.cardinality - obs.length)
    end

    def self.fixed_length_natural_array(length)
      if(length==0)
        return Domain.new(lambda{|el|el==[]},
                          lambda{|a|return 1},
                          lambda{|n|return []},
                          1)
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
            n += (FixedLengthArrayMethods::string_partitions(bits, length)*(2**bits))
            bits += 1
          end
          n += (a.join("").to_i(2))*FixedLengthArrayMethods::string_partitions(total_bits, length)
          n + FixedLengthArrayMethods::partition_lengths_to_n(a.map{|s|s.length})
        },
        lambda{|n|
          nn = 1
          bits = 0
          while(n > (k=FixedLengthArrayMethods::string_partitions(bits, length)*(2**bits)))
            n -= k
            bits += 1
          end
          k = FixedLengthArrayMethods::string_partitions(bits, length)
          n-=1
          s = "%0#{bits}d" % ((n/k).to_s(2).to_i)
          s = "" if bits == 0
          n = 1 + n % k

          parts = FixedLengthArrayMethods::nth_partition(s, length, n)
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

    def +(other)
      return other+self if other.class <=JoinedDomain
      Domain.join(self, other)
    end

    def self.join(*domains)
      JoinedDomain.new(*domains)
    end

    def self.set_of(domain)
      Domain::NATURAL_SET.map(
          lambda{|s|s.class == Set and s.all?{|ob|domain.domain.call(ob)}},
          lambda{|s|Set.new(s.map{|n|domain.from_n(n)})},
          lambda{|s|Set.new(s.map{|ob|domain.to_n(ob)})})
    end

    def self.fixed_size_set_of(domain, size)
      arr = Domain.fixed_length_natural_array(size)
      set = arr.map(lambda{|s|s.class == Set and s.size == size and s.all?{|el|Domain.is_n?(el)}},
              Domain::ARRAY_TO_SET,
              Domain::SET_TO_ARRAY)
      set.map(lambda{|s|s.class == Set and s.size == size and s.all?{|el|domain.domain.call(el)}},
              lambda{|s|Set.new(s.map{|el|domain.from_n(el)})},
              lambda{|s|Set.new(s.map{|el|domain.to_n(el)})})
    end

    def self.fixed_length_array_of(domain, size)
      Domain.cartesian_product(*([domain]*size))
    end

    def self.array_of(domain)
      Domain::NATURAL_ARRAY.map(
          lambda{|s|s.class == Array and s.all?{|ob|domain.domain.call(ob)}},
          lambda{|s|s.map{|n|domain.from_n(n)}},
          lambda{|s|s.map{|ob|domain.to_n(ob)}})
    end

    def self.nonempty_array_of(domain)
      self.array_of(domain).without([])
    end

    def map(domain_predicate, from_old_to_new, from_new_to_old)
      Domain.new(domain_predicate,
                 lambda{|ob|self.to_n(from_new_to_old.call(ob))},
                 lambda{|n|from_old_to_new.call(self.from_n(n))},
                 self.cardinality)
    end

    def self.cartesian_product(*domains)
      check_that("arguments must all be domains"){domains.all?{|d|d.class <= Domain}}
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
        infinite = Domain.new(lambda{|a|a.class==Array and a.length == infinites.length and a.zip(infinite_domains).all?{|el,d|d.domain.call(el)}},
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

    def Domain.converter(d1,d2)
      lambda{|ob|d2.from_n(d1.to_n(ob))}
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

    def take(n)
      (1..n).map{|x|self.from_n(x)}
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
      raise CerealizerException.new(message) unless yield
    end

    public 

    require 'cerealizer/base_domains'

    include Cerealizer::BaseDomains
  end
end
