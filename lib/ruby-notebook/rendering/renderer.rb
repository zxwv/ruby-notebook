module RubyNotebook
  class Renderer
    def initialize(notes)
      @notes = notes
    end

    def render_note(note, out_path)
      out_html = note.html_contents
      out_file_name = File.join(out_path, "#{note.name}.html")
      File.open(out_file_name, 'w') do |file|
        file.write(out_html)
      end
    end

    def render(out_path)
      out_path = File.expand_path(out_path)
      @notes.each do |note|
        render_note(note, out_path)
      end
    end
  end
end