module Cerealizer
  class Wrapper < Base
    def initialize(inner, encode, decode)
      @inner = inner
      @encode = encode
      @decode = decode
    end

    def to_n(ob)
      @inner.to_n(@encode.call(ob))
    end

    def from_n(n)
      @decode.call(@inner.from_n(n))
    end
  end
end
