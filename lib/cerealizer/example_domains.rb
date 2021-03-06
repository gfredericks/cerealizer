require 'cerealizer/domain'

module Cerealizer
  module ExampleDomains
    INTEGERS = Domain::NATURALS.map(
        lambda{|x|[Fixnum,Bignum].include?(x.class)},
        lambda{|n|return 0 if n == 1; (n / 2) * ((n % 2 == 1) ? -1 : 1)},
        lambda{|i|return 1 if i == 0; i.abs * 2 + (i < 0 ? 1 : 0)})
    
    ASCII_JSON = begin
      doms = Domain.recursively_define do |ob|
        value = Domain.join(
            Domain.finite_disjunction([false, true, nil]),
            ob.stub(:array),
            ob.stub(:object),
            Domain::ASCII,
            INTEGERS)
        ob.define(:value, value)
        ob.define(:array,Domain.array_of(ob.stub(:value)))

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
        ob.define(:object,Domain.join(object, Domain.finite_disjunction([{}])))
      end
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
    INTEGER_EXPRESSIONS = begin
      doms = Domain.recursively_define do |ob|
        ob.define(:expression, Domain.nonempty_array_of(ob.stub(:term)))
        ob.define(:term, Domain.nonempty_array_of(ob.stub(:factor)))
        ob.define(:factor, Domain.join(INTEGERS,ob.stub(:expression)))
      end
      doms[:expression]
    end
  end
end
