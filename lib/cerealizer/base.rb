module Cerealizer
  class Base
    def to_hex(x)
      self.to_n(x).to_s(16)
    end

    def from_hex(s)
      self.from_n(s.to_i(16))
    end
  end
end
