$LOAD_PATH << './'

require 'fox16'
include Fox
require 'uri'

class MainWindow < FXMainWindow
  def initialize(application)
    super(application, "URL Parser", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 366, :height => 222)
    self.layoutHints = LAYOUT_EXPLICIT

    @label_url = FXLabel.new(self, ' URL:', nil, LABEL_NORMAL, 10, 10, 25, 23)
    @label_url.layoutHints = LAYOUT_EXPLICIT

    @input_url = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 40, 10, 320, 23)
    @input_url.layoutHints = LAYOUT_EXPLICIT

    @label_scheme = FXLabel.new(self, 'Scheme:', nil, LABEL_NORMAL, 10, 62, 84, 23)
    @label_scheme.layoutHints = LAYOUT_EXPLICIT
    @label_scheme.justify = JUSTIFY_RIGHT
    @input_scheme = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 62, 260, 23)
    @input_scheme.layoutHints = LAYOUT_EXPLICIT

    @label_host = FXLabel.new(self, 'Host:', nil, LABEL_NORMAL, 10, 88, 84, 23) #26
    @label_host.layoutHints = LAYOUT_EXPLICIT
    @label_host.justify = JUSTIFY_RIGHT
    @input_host = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 88, 260, 23)
    @input_host.layoutHints = LAYOUT_EXPLICIT

    @label_path = FXLabel.new(self, 'Path:', nil, LABEL_NORMAL, 10, 114, 84, 23)
    @label_path.layoutHints = LAYOUT_EXPLICIT
    @label_path.justify = JUSTIFY_RIGHT
    @input_path = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 114, 260, 23)
    @input_path.layoutHints = LAYOUT_EXPLICIT

    @label_query = FXLabel.new(self, 'Query:', nil, LABEL_NORMAL, 10, 140, 84, 23)
    @label_query.layoutHints = LAYOUT_EXPLICIT
    @label_query.justify = JUSTIFY_RIGHT
    @input_query = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 140, 260, 23)
    @input_query.layoutHints = LAYOUT_EXPLICIT

    @label_fragment = FXLabel.new(self, 'Fragment:', nil, LABEL_NORMAL, 10, 166, 84, 23)
    @label_fragment.layoutHints = LAYOUT_EXPLICIT
    @label_fragment.justify = JUSTIFY_RIGHT
    @input_fragment = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 166, 260, 23)
    @input_fragment.layoutHints = LAYOUT_EXPLICIT

    @button_parse = FXButton.new(self, 'Parse', nil, nil, 0, BUTTON_NORMAL, 320, 36, 38, 23)
    @button_parse.layoutHints = LAYOUT_EXPLICIT

    @button_construct = FXButton.new(self, 'Construct', nil, nil, 0, BUTTON_NORMAL, 298, 192, 60, 23)
    @button_construct.layoutHints = LAYOUT_EXPLICIT

    @button_parse.connect(SEL_COMMAND) { |sender, selector, data|
      @input_url.backColor = Fox.FXRGB(255, 255, 255)
      begin
        uri = URI(@input_url.text)
        @input_scheme.text = uri.scheme
        @input_host.text = uri.host
        @input_path.text = uri.path
        @input_query.text = uri.query
        @input_fragment.text = uri.fragment
      rescue
        # Bad URI dialog!
        @input_url.backColor = Fox.FXRGB(255, 200, 200)
      end
    }

    @button_construct.connect(SEL_COMMAND) { |sender, selector, data|
      @input_url.backColor = Fox.FXRGB(255, 255, 255)
      begin
        uri = URI('')
        uri.scheme = @input_scheme.text
        uri.host = @input_host.text
        uri.path = @input_path.text
        uri.query = @input_query.text
        uri.fragment = @input_fragment.text
        @input_url.text = uri.to_s
      rescue
        # Bad URI dialog!
        @input_url.text = ''
        @input_url.backColor = Fox.FXRGB(255, 200, 200)
      end
    }
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    enable()
  end
end

if __FILE__ == $0
  application = FXApp.new("URL Parser", "gabor.major@csn.hu")
  MainWindow.new(application)
  application.create
  application.run
end