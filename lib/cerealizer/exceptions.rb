module Cerealizer
  module Exceptions
    class CerealizerException < Exception
    end
    class BadDataException < CerealizerException
    end
    class BadDomainException < CerealizerException
    end
  end
end
