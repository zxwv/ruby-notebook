require 'erubis'
require 'redcarpet'
require 'nokogiri'

require_relative '../note'
require_relative 'note_dsl_helper'
require_relative 'metadata_postprocessor'

module RubyNotebook
  class Parser
    class << self
      def parse_directory(in_path)
        dir_path = File.expand_path(in_path)
        dir = Dir.new(dir_path)
        file_paths = dir.entries.map do |elem|
          File.join(dir_path, elem)
        end.reject do |elem|
          File.directory?(elem) || File.symlink?(elem)
        end
        file_paths.map do |elem|
          parser = Parser.new(elem)
          parser.run
          parser.to_note
        end
      end
    end

    def initialize(file_name)
      @file_path = File.expand_path(file_name)
      @dsl_helper = NoteDslHelper.new
    end

    def run
      return @parser_result if @parser_result
      load_file
      erb_step
      markdown_step
      metadata_postprocessing_step
      @parser_result = { :file_name => File.basename(@file_path),
                         :file_path => @file_path,
                         :input => @raw_input,
                         :erb => @erb_output,
                         :markdown => @markdown_output,
                         :output => @markdown_output,
                         :raw_metadata => @raw_metadata,
                         :metadata => @metadata }
    end

    def to_note
      run
      return @note_result if @note_result
      @note_result = Note.new
      @note_result.name = File.basename(@parser_result[:file_path], '.*')
      @note_result.html_contents = @parser_result[:output]
      @note_result.plain_contents = Nokogiri::HTML(@parser_result[:output]).content
      @note_result.metadata = @parser_result[:metadata]
      @note_result
    end

    private

    def load_file
      @raw_input = IO.read @file_path
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
