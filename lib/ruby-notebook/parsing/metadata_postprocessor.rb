module RubyNotebook
  module MetadataPostprocessor
    class << self
      def process_datetime(datetime)
        DateTime.parse datetime
      end

      alias_method :created, :process_datetime
      alias_method :modified, :process_datetime
    end
  end
end
