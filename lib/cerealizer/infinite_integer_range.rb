module Cerealizer
  class InfiniteIntegerRange < Base
    @@single = InfiniteIntegerRange.new
    @@both = @@single.wrap(lambda{|x|1+(2 * x + (x < 0 ? 1 : 0)).abs},
                           lambda{|x|(x / 2)*(x % 2 == 0 ? -1 : 1)})
    def InfiniteIntegerRange.open_right(min = 1)
      if(min != 1)
        @@single.wrap(lambda{|x|x - min + 1}, lambda{|x|x + min - 1})
      else
        @@single
      end
    end

    def InfiniteIntegerRange.open_left(max = -1)
      InfiniteIntegerRange.open_right(-max).wrap(lambda{|x|-x},lambda{|x|-x})
    end

    def InfiniteIntegerRange.open_both
      @@both
    end

    def to_n(i)
      raise BadDomainException.new unless i > 0
      i
    end

    def from_n(n)
      raise BadDataException.new unless n > 0
      n
    end

    private
    def initialize
    end
  end
end
