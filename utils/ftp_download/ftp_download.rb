$LOAD_PATH << './'

require 'fox16'
include Fox
require 'net/ftp'

class MainWindow < FXMainWindow
  def initialize(application)
    super(application, "FTP Download", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 366, :height => 530)
    self.layoutHints = LAYOUT_EXPLICIT

    @label_hostname = FXLabel.new(self, 'Host name:', nil, LABEL_NORMAL, 10, 10, 84, 23)
    @label_hostname.layoutHints = LAYOUT_EXPLICIT
    @label_hostname.justify = JUSTIFY_RIGHT
    @input_hostname = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 10, 150, 23)
    @input_hostname.layoutHints = LAYOUT_EXPLICIT

    @label_username = FXLabel.new(self, 'Username:', nil, LABEL_NORMAL, 10, 36, 84, 23)
    @label_username.layoutHints = LAYOUT_EXPLICIT
    @label_username.justify = JUSTIFY_RIGHT
    @input_username = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 36, 150, 23)
    @input_username.layoutHints = LAYOUT_EXPLICIT

    @label_password = FXLabel.new(self, 'Password:', nil, LABEL_NORMAL, 10, 62, 84, 23)
    @label_password.layoutHints = LAYOUT_EXPLICIT
    @label_password.justify = JUSTIFY_RIGHT
    @input_password = FXTextField.new(self, 40, nil, 0, TEXTFIELD_PASSWD | TEXTFIELD_NORMAL, 100, 62, 150, 23)
    @input_password.layoutHints = LAYOUT_EXPLICIT

    @checkbox_passive = FXCheckButton.new(self, 'Passive mode', nil, 0, CHECKBUTTON_NORMAL, 263, 10, 100, 23)
    @checkbox_passive.layoutHints = LAYOUT_EXPLICIT

    line1 = FXHorizontalSeparator.new(self, SEPARATOR_GROOVE, 10, 90, 350, 10)
    line1.layoutHints = LAYOUT_EXPLICIT

    @label_remote_dir = FXLabel.new(self, 'Remote dir:', nil, LABEL_NORMAL, 10, 104, 84, 23)
    @label_remote_dir.layoutHints = LAYOUT_EXPLICIT
    @label_remote_dir.justify = JUSTIFY_RIGHT
    @input_remote_dir = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 104, 260, 23)
    @input_remote_dir.layoutHints = LAYOUT_EXPLICIT
    @input_remote_dir.text = '/'

    @label_remote_files = FXLabel.new(self, 'File(s):', nil, LABEL_NORMAL, 10, 136, 84, 23)
    @label_remote_files.layoutHints = LAYOUT_EXPLICIT
    @label_remote_files.justify = JUSTIFY_RIGHT
    @input_remote_files = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 136, 260, 23)
    @input_remote_files.layoutHints = LAYOUT_EXPLICIT
    @input_remote_files.text = '*.*'

    line2 = FXHorizontalSeparator.new(self, SEPARATOR_GROOVE, 10, 163, 350, 10)
    line2.layoutHints = LAYOUT_EXPLICIT

    @dir_selector = FXDirSelector.new(self, nil, 0, 0, 10, 177, 350, 350)
    @dir_selector.layoutHints = LAYOUT_EXPLICIT
    @dir_selector.cancelButton.hide
    @dir_selector.acceptButton.text = 'Start'

    @dir_selector.acceptButton.connect(SEL_COMMAND) { |sender, selector, data|
      begin
        username = @input_username.text
        password = @input_password.text
        pattern = @input_remote_files.text.gsub('.', '\.').gsub('*', '.+').gsub('?', '.')

        if username.length > 0 && password.length > 0
          ftp = Net::FTP.new(@input_hostname.text, username, password)
        else
          ftp = Net::FTP.new(@input_hostname.text)
        end
        ftp.passive = @checkbox_passive.checked?
        ftp.login

        files = ftp.nlst(@input_remote_dir.text)
        files.each { |file|
          puts file.to_s if file.to_s =~ /^#{pattern}/
        }

        ftp.close
      rescue
        # Error dialog!
        ftp.close unless ftp.nil?
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
  application = FXApp.new("FTP Download", "gabor.major@csn.hu")
  MainWindow.new(application)
  application.create
  application.run
end