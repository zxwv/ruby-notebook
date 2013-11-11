require 'erubis'
require 'redcarpet'

require_relative 'note_dsl_helper'
require_relative 'metadata_postprocessor'

module RubyNotebook
  class Parser
    def initialize(filename)
      @filename = filename
      @dsl_helper = NoteDslHelper.new
    end

    def run
      load_file
      erb_step
      markdown_step
      metadata_postprocessing_step
      { :filename => File.basename(@filename),
        :input => @raw_input,
        :erb => @erb_output,
        :markdown => @markdown_output,
        :output => @markdown_output,
        :raw_metadata => @raw_metadata,
        :metadata => @metadata }
    end

    private

    def load_file
      @raw_input = IO.read @filename
    end

    def erb_step
      erubis = Erubis::Eruby.new @raw_input
      @erb_output = erubis.result @dsl_helper.binding_for_erb
    end

    def markdown_step
      redcarpet = Redcarpet::Markdown.new Redcarpet::Render::HTML
      @markdown_output = redcarpet.render @erb_output
      @raw_metadata = @dsl_helper.metadata_collector.collected
    end

    def metadata_postprocessing_step
      @metadata = { }
      @raw_metadata.each_pair do |key, val|
        if MetadataPostprocessor.respond_to? key
          @metadata[key] = MetadataPostprocessor.send key, val
        else
          @metadata[key] = val
        end
      end
    end
  end
end
