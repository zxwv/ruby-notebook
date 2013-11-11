require 'nokogiri'

require_relative '../lib/ruby-notebook/parsing/parser'

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
      @parse_result.should be_a(Hash)
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
      @nokogiri_output = Nokogiri::HTML(@parse_result[:output])
    end

    it 'should run erb processing followed by markdown processing in correct order' do
      @nokogiri_output.content.should =~ /this example uses both embedded ruby and markdown/i
      @nokogiri_output.content.should =~ /in fact, you can embed markdown inside your erb/i
      @nokogiri_output.xpath('//em').count.should == 2
      @nokogiri_output.xpath('//strong').count.should == 2
    end
  end

  context 'parsing example 4: metadata' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0004_metadata.txt'
      @parse_result = @parser.run
      @note_result = @parser.to_note
      @metadata_hash = { :title => 'Example with metadata',
                         :created => '2013-11-10T09:39:38Z',
                         :modified => '2013-11-10T09:39:38Z',
                         :path => ['examples', 'widgets'],
                         :tags => ['widgets', 'sprockets', 'doodads'] }
    end

    it 'should successfully extract metadata from metadata block in erb' do
      @metadata_hash.each_pair do |key, val|
        @parse_result[:raw_metadata][key].should == val
      end
    end

    it 'should successfully post-process metadata where such rules are defined' do
      [:created, :modified].each do |field|
        @parse_result[:metadata][field].should == DateTime.parse(@parse_result[:raw_metadata][field])
      end
    end

    it 'should successfully convert output into a Note' do
      @note_result.should_not be_nil
      @note_result.should be_a(RubyNotebook::Note)
      @note_result.name.should == '0004_metadata'
      @metadata_hash.each_pair do |key, val|
        if RubyNotebook::MetadataPostprocessor.respond_to? key
          @note_result.metadata[key].should == RubyNotebook::MetadataPostprocessor.send(key, val)
        else
          @note_result.metadata[key].should == val
        end
      end
    end
  end

  context 'parsing example 5: fizzbuzz' do
    before :each do
      @parser = RubyNotebook::Parser.new 'spec_examples/0005_fizzbuzz.txt'
      @parse_result = @parser.run
      @note_result = @parser.to_note
      @nokogiri_output = Nokogiri::HTML(@note_result.html_contents)
    end

    it 'should contain the dynamically generated count up' do
      @nokogiri_output.xpath('//li').count.should == 100
    end

    it 'should execute both angle-percent and angle-percent-equal blocks correctly, thus computing FizzBuzz' do
      fizzbuzz_nodes = @nokogiri_output.xpath('//li')
      (1..100).each do |num|
        node = fizzbuzz_nodes[num - 1]
        div3 = num % 3 == 0
        div5 = num % 5 == 0
        if div3 && div5
          node.content.should == 'FizzBuzz'
        elsif div3
          node.content.should == 'Fizz'
        elsif div5
          node.content.should == 'Buzz'
        else
          node.content.should == num.to_s
        end
      end
    end
  end
end
