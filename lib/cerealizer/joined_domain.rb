require 'cerealizer/domain'

module Cerealizer
  class JoinedDomain < Domain
    def initialize(*domains)
      @domains = domains
      Domain.check_that("arguments must all be domains"){domains.all?{|d|d.class <= Domain}}
      Domain.check_that("at least two domains are required"){domains.length > 1}
      cards = domains.map{|d|d.cardinality}
      min = cards.reject{|c|c == :aleph_null}.min
      zipped = domains.zip((1..domains.length).to_a)
      @domain = lambda{|a|(domains).any?{|d|d.domain.call(a)}}
      @to_n = lambda{|ob|
                       doms = zipped.select{|d,i|d.domain.call(ob)}
                       Domain.check_that("object must be part of exactly one domain"){doms.length == 1}
                       dom,i = doms[0]
                       (dom.to_n(ob) - 1)*domains.length + i
                     }
      @from_n = lambda{|n|
                   n-=1
                   domains[n % domains.length].from_n(1+n/domains.length)
                 }
      @cardinality = (cards.uniq == [:aleph_null] ? :aleph_null : cards.length * min)
      spread_even=Domain.new(@domain,@to_n,@from_n,@cardinality)

      if(min and cards.uniq.length > 1)
        chomped = domains.reject{|d|d.cardinality == min}.map{|d|d.drop(min)}
        dd = (chomped.length == 1 ? chomped[0] : Domain.join(*chomped))
        ceiling = min * cards.length
        @to_n = lambda{|ob|
                   n = spread_even.to_n(ob)
                   return n if n <= ceiling
                   ceiling + dd.to_n(ob)
                 }
        @from_n = lambda{|n|
                     if(n > ceiling)
                       dd.from_n(n-ceiling)
                     else
                       spread_even.from_n(n)
                     end
                   }
        @cardinality = (cards.any?{|c|c == :aleph_null} ? :aleph_null : cards.inject{|u,v|u+v})
      end
    end
    
    def +(other)
      JoinedDomain.new(*(@domains + [other]))
    end
  end
end
