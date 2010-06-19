module Cerealizer
  module BaseDomains
    NATURALS = Domain.new(
      lambda{|ob|Domain.is_n?(ob)},
      lambda{|x|x}, 
      lambda{|x|x},
      :aleph_null)

    ASCII = Domain.string(" !\"\#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~")

    NATURAL_ARRAY = 
      begin
        ternary = Domain.string("012")
        split_twos = lambda do |s|
          i = s.index('2')
          return [s] unless i
          [s[0...i]] + split_twos.call(s[(i+1)..-1])
        end
        Domain.new(
          lambda{|a|a.class == Array and a.all?{|el|Domain.is_n?(el)}},
          lambda{|a|return 1 if a == []; 1 + ternary.to_n(a.map{|x|x.to_s(2)[1..-1]}.join("2"))},
          lambda{|n|return [] if n == 1; split_twos.call(ternary.from_n(n-1)).map{|x|("1"+x).to_i(2)}},
          :aleph_null)
      end

    NATURAL_SET = Domain.new(
      lambda{|ob|ob.class == Set and ob.all?{|el|Domain.is_n?(el)}},
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
