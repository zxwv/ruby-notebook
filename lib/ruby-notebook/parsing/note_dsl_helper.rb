require_relative 'params_collector'

module RubyNotebook
  class NoteDslHelper
    attr_reader :metadata_collector

    def initialize
      @metadata_collector = ParamsCollector.new
    end

    def binding_for_erb
      binding
    end

    def metadata(&blk)
      @metadata_collector.instance_eval &blk
    end
  end
end
