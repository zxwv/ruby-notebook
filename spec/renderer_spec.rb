require 'fakefs/safe'

require_relative '../lib/ruby-notebook'

describe RubyNotebook::Renderer do
  before :each do
    @notes = RubyNotebook::Parser.parse_directory './spec_examples'
    FakeFS.activate!
    Dir.mkdir './spec_examples_render_out'
  end

  after :each do
    FakeFS::FileSystem.clear
    FakeFS.deactivate!
  end

  context 'rendering all notes' do
    before :each do
      @renderer = RubyNotebook::Renderer.new @notes
      @renderer.render './spec_examples_render_out'
    end

    it 'should create or overwrite the output files' do
      @notes.each do |note|
        file_name = File.join('./spec_examples_render_out', "#{note.name}.html")
        File.exists?(file_name).should be_true
      end
    end

    it 'should write appropriate html output to the output files' do
      @notes.each do |note|
        file_name = File.join('./spec_examples_render_out', "#{note.name}.html")
        file_contents = File.read(file_name)
        file_contents.should == note.html_contents
      end
    end
  end
end