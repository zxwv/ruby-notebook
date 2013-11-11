require 'nokogiri'

require_relative '../lib/ruby-notebook'

describe RubyNotebook::Parser do
  context 'parsing example 0: plain text' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0000_plain_text.txt'
      @parse_result = @parser.run
    end

    it 'should parse successfully' do
      @parse_result.should_not be_nil
    end

    it 'should produce the correct fields in the output' do
      @parse_result.should respond_to(:has_key?)
      [:input, :erb, :markdown, :output, :metadata].each do |field_name|
        @parse_result.has_key?(field_name).should be_true
      end
    end
  end

  context 'parsing example 1: erb' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0001_erb.txt'
      @parse_result = @parser.run
    end

    it 'should actually run erb processing' do
      @parse_result[:output].should =~ /this example uses embedded ruby/i
    end
  end

  context 'parsing example 2: markdown' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0002_markdown.txt'
      @parse_result = @parser.run
      @nokogiri_output = Nokogiri::HTML(@parse_result[:output])
    end

    it 'should actually run markdown processing' do
      @nokogiri_output.content.should =~ /this example uses markdown/i
      strong_text = @nokogiri_output.xpath('/html/body/p/strong')
      strong_text.count.should == 1
      strong_text[0].content.should =~ /markdown/i
    end
  end

  context 'parsing example 3: erb and markdown' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0003_erb_and_markdown.txt'
      @parse_result = @parser.run
    end

    it 'should run erb processing followed by markdown processing' do

    end
  end

  context 'parsing example 4: metadata' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0004_metadata.txt'
      @parse_result = @parser.run
    end

    it 'should successfully extract metadata from metadata block in erb' do
      metadata_hash = { :title => 'Example with metadata',
                        :created => '2013-11-10T09:39:38Z',
                        :modified => '2013-11-10T09:39:38Z',
                        :path => ['examples', 'widgets'],
                        :tags => ['widgets', 'sprockets', 'doodads'] }
      metadata_hash.each_pair do |key, val|
        @parse_result[:raw_metadata][key].should == val
      end
    end

    it 'should successfully post-process metadata where such rules are defined' do
      [:created, :modified].each do |field|
        @parse_result[:metadata][field].should == DateTime.parse(@parse_result[:raw_metadata][field])
      end
    end
  end
end