module Cerealizer
  class InfiniteIntegerRange < Base
    # I can't do this in any nice way :(
    def initialize(opts)
      min = opts[:min] || 0
      max = opts[:max] || :infinity
      unless([min,max].include?(:infinity))
        
      end
    end
  end
end
