module RubyNotebook
  class ParamsCollector
    attr_reader :collected

    def initialize
      @collected = { }
    end

    def method_missing(sym, *args)
      @collected[sym] = args[0]
    end
  end
end
