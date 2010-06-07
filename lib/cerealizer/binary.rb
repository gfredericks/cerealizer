module Cerealizer
  class Binary < Base
    # Should check that chunksize > 0
    def initialize(chunksize = 8)
      @chunksize = chunksize
    end

    def to_n(bin, opts = {})
      if(opts[:length] and opts[:length] % @chunksize > 0)
        raise BadDomainException.new
      end
      n = 1
      if(opts[:format] == :string)
        n = ("1" + bin).to_i(2)
      else
        length = opts[:length] || bin.length * 8
        while(length > 7)
          raise BadDomainException.new if bin.empty?
          length -=8
          n<<=8
          n+=bin[0]
          bin = bin[1..-1]
        end
        if(length > 0)
          n<<=length
          n+=(bin[0] >> (8 - length))
        end
      end
      n
    end

    def from_n(n, opts = {})
      #TODO: Not finished at all
      if(opts[:format] == :string)
        n.to_s(2)[1..-1]
      end
      length = opts[:length] || :something
      while(n > 1)
      end
    end
  end
end
