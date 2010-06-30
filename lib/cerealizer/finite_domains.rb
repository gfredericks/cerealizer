require 'cerealizer/domain'

module Cerealizer
  module FiniteDomains
    def fixed_length_strings(alphabet, length)

    end

    def max_length_strings(alphabet, max_length)

    end

    def integer_range(range)
      Domain.new(lambda{|x|Domain.is_n?(x) and range.include?(x)},
                 lambda{|x|x - range.begin + 1},
                 lambda{|n|n - 1 + range.begin},
                 range.end - range.begin + (range.exclude_end? ? 0 : 1))
    end
  end
end
