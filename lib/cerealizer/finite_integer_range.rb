module Cerealizer
  class FiniteIntegerRange < Base
    def initialize(*args)
      if(args.length == 1 and args[0].class == Range)
        @range = args[0]
      elsif(args.length == 2 and args.all?{|a|a.class == Fixnum})
        @range = args[0]..args[1]
        raise CerealizerException.new("Range must be positive length") unless args[1] > args[0]
      else
        raise CerealizerException.new("Bad argument to FiniteIntegerRange constructor")
      end
    end

    def count
      @range.end - @range.begin + 1
    end

    def to_n(i)
      raise BadDomainException.new unless @range.include?(i)
      i - @range.begin - 1 
    end

    def from_n(n)
      res = n + @range.begin + 1
      raise BadDataException.new unless @range.include? res
      res
    end
  end
end
