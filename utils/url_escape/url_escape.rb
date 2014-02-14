$LOAD_PATH << './'

require 'fox16'
include Fox
require 'uri'

class MainWindow < FXMainWindow
  def initialize(application)
    super(application, "URL Escape", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 366, :height => 93)
    self.layoutHints = LAYOUT_EXPLICIT

    @label_url = FXLabel.new(self, ' URL:', nil, LABEL_NORMAL, 10, 10, 25, 23)
    @label_url.layoutHints = LAYOUT_EXPLICIT

    @input_url = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 40, 10, 320, 23)
    @input_url.layoutHints = LAYOUT_EXPLICIT

    @label_result = FXLabel.new(self, ' >>>', nil, LABEL_NORMAL, 10, 62, 25, 23)
    @label_result.layoutHints = LAYOUT_EXPLICIT

    @input_result = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 40, 62, 320, 23)
    @input_result.layoutHints = LAYOUT_EXPLICIT

    @button_escape = FXButton.new(self, 'Escape', nil, nil, 0, BUTTON_NORMAL, 200, 36, 77, 23)
    @button_escape.layoutHints = LAYOUT_EXPLICIT

    @button_unescape = FXButton.new(self, 'Unescape', nil, nil, 0, BUTTON_NORMAL, 280, 36, 77, 23)
    @button_unescape.layoutHints = LAYOUT_EXPLICIT

    @button_escape.connect(SEL_COMMAND) { |sender, selector, data|
      @input_result.text = URI.escape(@input_url.text)
    }
    @button_unescape.connect(SEL_COMMAND) { |sender, selector, data|
      @input_result.text = URI.unescape(@input_url.text)
    }
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    enable()
  end
end

if __FILE__ == $0
  application = FXApp.new("URL Escape", "gabor.major@csn.hu")
  MainWindow.new(application)
  application.create
  application.run
end