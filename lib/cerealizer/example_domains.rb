require 'cerealizer/domain'

module Cerealizer
  module ExampleDomains
    INTEGERS = Domain::NATURALS.map(
        lambda{|x|[Fixnum,Bignum].include?(x.class)},
        lambda{|n|return 0 if n == 1; (n / 2) * ((n % 2 == 1) ? -1 : 1)},
        lambda{|i|return 1 if i == 0; i.abs * 2 + (i < 0 ? 1 : 0)})
    
    ASCII_JSON = begin
      doms = Domain.recursively_define do |ob|
        ob.define(:value) do
          Domain.join(
              Domain.finite_disjunction([false, true, nil]),
              ob.stub(:array),
              ob.stub(:object),
              Domain::ASCII,
              INTEGERS)
        end
        ob.define(:array) do
          Domain.array_of(ob.stub(:value))
        end

        ob.define(:object) do
          string_sets_and_nums = Domain.cartesian_product(Domain.set_of(Domain::ASCII).without(Set.new),Domain::NATURALS)
          memoizer = {1=>ob.stub(:value).map(lambda{|a|a.class==Array and a.length==1 and ob.stub(:value).domain.call(a[0])},
              lambda{|v|[v]},
              lambda{|a|a[0]})}
          fixed_array_of_values = lambda do |n|
            memoizer[n] ||= Domain.cartesian_product(*([ob.stub(:value)]*n))
          end
          object = string_sets_and_nums.map(
              lambda{|hm|hm.class == Hash and hm.keys.all?{|k|Domain::ASCII.domain.call(k)} and hm.values.all?{|v|ob.stub(:value).domain.call(v)}},
              lambda{|a|
                strings,nat = a
                values = fixed_array_of_values.call(strings.size).from_n(nat)
                strings.to_a.sort.zip(values).map{|k,v|{k=>v}}.inject{|u,v|u.merge(v)}
              },
              lambda{|hm|
                [Set.new(hm.keys), fixed_array_of_values.call(hm.size).to_n(hm.keys.sort.map{|k|hm[k]})]
              })
          Domain.join(object, Domain.finite_disjunction([{}]))
        end
      end
      #doms[:value].to_s=lambda{|v|self.json_value_to_s(v)}
      doms[:value]
    end

    def self.json_value_to_s(v)
      if(v.class == Hash)
        "{"+v.map{|k,vv|k.inspect+":"+json_value_to_s(vv)}.join(",")+"}"
      elsif(v.class == Array)
        "["+v.map{|el|json_value_to_s(el)}.join(",")+"]"
      elsif(v.class == String)
        v.inspect
      elsif(v.class == Fixnum or v.class == Bignum)
        v.to_s
      else
        {false=>"false", true=>"true", nil=>"null"}[v]
      end
    end

    def sentences(nouns, verbs, adjectives, adverbs)
      doms = Domain.recursively_define do |ob|
        ob.define(:noun_phrase) do
          Domain.join(nouns,
                      Domain.cartesian_product(adjectives, nouns),
                      Donain.cartesian_product(adjectives, adjectives, nouns))
        end

        ob.define(:verb_phrase) do
          Domain.join(verbs,
                      Domain.cartesian_product(verbs, ob.stub(:noun_phrases)),
                      Domain.cartesian_product(verbs, adverbs))
        end
      end
    end
  end
end
