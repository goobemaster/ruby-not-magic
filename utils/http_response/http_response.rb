$LOAD_PATH << './'

require 'fox16'
include Fox
require 'net/http'

class MainWindow < FXMainWindow
  def initialize(application)
    super(application, "HTTP Response", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 366, :height => 300)
    self.layoutHints = LAYOUT_EXPLICIT

    @label_url = FXLabel.new(self, ' URL:', nil, LABEL_NORMAL, 10, 10, 25, 23)
    @label_url.layoutHints = LAYOUT_EXPLICIT

    @input_url = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 40, 10, 320, 23)
    @input_url.layoutHints = LAYOUT_EXPLICIT
    @input_url.text = 'http://'

    @button_get = FXButton.new(self, 'GET', nil, nil, 0, BUTTON_NORMAL, 330, 36, 28, 23)
    @button_get.layoutHints = LAYOUT_EXPLICIT

    @label_response = FXLabel.new(self, ' Response code:', nil, LABEL_NORMAL, 10, 36, 84, 23)
    @label_response.layoutHints = LAYOUT_EXPLICIT

    @label_response_code = FXLabel.new(self, '', nil, LABEL_NORMAL, 100, 36, 160, 23)
    @label_response_code.layoutHints = LAYOUT_EXPLICIT
    @label_response_code.textColor = color('')
    @label_response_code.justify = JUSTIFY_LEFT

    @text_response_body = FXText.new(self, nil, 0, TEXT_READONLY, 10, 66, 346, 222)
    @text_response_body.layoutHints = LAYOUT_EXPLICIT
    @text_response_body.editable = false
    @text_response_body.text = 'Response has no body'

    @button_get.connect(SEL_COMMAND) { |sender, selector, data|
      @text_response_body.text = 'Response has no body'
      response = get_response(@input_url.text)
      unless response.kind_of?(Net::HTTPResponse)
        @label_response_code.text = ''
        @label_response_code.textColor = color('')
        message_box = FXMessageBox.warning(self, MBOX_OK, 'Error', "Could not get the response:\r\n\r\n#{response}")
      else
        @label_response_code.text = "#{response.code.to_s} #{response.message.to_s}"
        @text_response_body.text = response.body if response.kind_of?(Net::HTTPSuccess)
        case response.code.to_s[0]
          when '2'
            @label_response_code.textColor = color('green')
          when '3'
            @label_response_code.textColor = color('blue')
          when '4', '5'
            @label_response_code.textColor = color('red')
          else
            @label_response_code.textColor = color('')
        end
      end
    }
  end

  def get_response(url)
    begin
      return Net::HTTP.get_response(URI(url))
    rescue Exception => e
      e.message
    end
  end

  def color(name)
    case name.downcase
      when 'green'
        return Fox.FXRGB(32, 200, 32)
      when 'red'
        return Fox.FXRGB(200, 32, 32)
      when 'blue'
        return Fox.FXRGB(32, 32, 200)
      else
        return Fox.FXRGB(0, 0, 0)
    end
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    enable()
  end
end

if __FILE__ == $0
  application = FXApp.new("HTTP Response", "gabor.major@csn.hu")
  MainWindow.new(application)
  application.create
  application.run
end