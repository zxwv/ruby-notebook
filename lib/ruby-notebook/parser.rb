require 'erubis'
require 'redcarpet'

require_relative 'params_collector'

module RubyNotebook
  class Parser
    def initialize(filename)
      @filename = filename
      @params_collector = ParamsCollector.new
    end

    def run
      load_file
      erb_step
      markdown_step
      { :input => @raw_input,
        :erb => @erb_output,
        :markdown => @markdown_output,
        :metadata => @metadata_output }
    end

    private

    def metadata(&blk)
      @params_collector.instance_eval &blk
    end

    def load_file
      @raw_input = IO.read @filename
    end

    def erb_step
      erubis = Erubis::Eruby.new @raw_input
      @erb_output = erubis.result binding
      @metadata_output = @params_collector.collected
    end

    def markdown_step
      redcarpet = Redcarpet::Markdown.new Redcarpet::Render::HTML
      @markdown_output = redcarpet.render @erb_output
    end
  end
end
