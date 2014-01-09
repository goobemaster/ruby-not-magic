$LOAD_PATH << './'

require 'fox16'
include Fox

class MastermindWindow < FXMainWindow
  attr_accessor :images
  attr_accessor :board

  def initialize(application)
    super(application, "Mastermind", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 316, :height => 455)
    load_images()

    self.icon = @images['mastermind']
    self.miniIcon = @images['mastermind']
    self.backColor = Fox.FXRGB(255, 255, 255)
    self.layoutHints = LAYOUT_EXPLICIT

    @board = FXImageFrame.new(self, @images['board'], 0, 0, 0, 316, 455)
    @board.layoutHints = LAYOUT_EXPLICIT
    @board.show()
  end

  def load_images()
    @images = Hash.new()
    @images['mastermind'] = FXICOIcon.new(getApp(), File.open('mastermind.ico', "rb").read(), 0, 32, 32)
    @images['board'] = FXPNGImage.new(getApp(), File.open('board.png', "rb").read(), IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP, 316, 455)
    @images['cb'] = FXPNGImage.new(getApp(), File.open('cb.png', "rb").read(), IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP, 6, 6)
    @images['cw'] = FXPNGImage.new(getApp(), File.open('cw.png', "rb").read(), IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP, 6, 6)
    (0..5).each { |i|
      @images["c#{i.to_s}"] = FXPNGImage.new(getApp(), File.open("c#{i.to_s}.png", "rb").read(), IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP, 16, 16)
    }
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    enable()
  end
end

if __FILE__ == $0
  application = FXApp.new("Mastermind", "gabor.major@csn.hu")
  MastermindWindow.new(application)
  application.create
  application.run
end


#application = FXApp.new
#
#icon = FXICOIcon.new(application, File.open("mastermind.ico", "rb").read(), 0, 0, 32, 32)
#transparent_image = FXPNGImage.new(application, File.open("nil.png", "rb").read(), 0, 26, 26)
#board_image = FXPNGImage.new(application, File.open("board.png", "rb").read(), IMAGE_KEEP|IMAGE_SHMI|IMAGE_SHMP , 316, 455)
#$color_image = Array.new()
#(0..5).each { |i|
#  $color_image[i] = FXPNGImage.new(application, File.open("c#{i.to_s}.png", "rb").read(), 0, 16, 16)
#}
#black_image = FXPNGImage.new(application, File.open("cb.png", "rb").read(), 0, 6, 6)
#white_image = FXPNGImage.new(application, File.open("cw.png", "rb").read(), 0, 6, 6)
#
#$form = FXMainWindow.new(application, "Mastermind", icon, icon, DECOR_ALL, 0, 0, 316, 455)
#$form.backColor = Fox.FXRGB(255, 255, 255)
#$form.layoutHints = LAYOUT_EXPLICIT
#
#board = FXImageFrame.new($form, board_image, 0, 0, 0, 316, 455)
#board.layoutHints = LAYOUT_EXPLICIT
#board.show()
#
#$cursor = FXImageFrame.new($form, $color_image[5], 0, 280, 289, 26, 26)
#$cursor_color = 5
#$cursor.show()
#
#cyan_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 400, 139, 26, 26)
#cyan_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 5; $cursor.image = $color_image[$cursor_color]; puts "Cyan" }
#cyan_button.show()
#
#blue_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 280, 169, 26, 26)
#blue_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 4; $cursor.image = $color_image[$cursor_color] }
#blue_button.show()
#
#red_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 280, 199, 26, 26)
#red_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 3; $cursor.image = $color_image[$cursor_color] }
#red_button.show()
#
#yellow_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 280, 229, 26, 26)
#yellow_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 2; $cursor.image = $color_image[$cursor_color] }
#yellow_button.show()
#
#purple_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 280, 259, 26, 26)
#purple_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 1; $cursor.image = $color_image[$cursor_color] }
#purple_button.show()
#
#green_button = FXImageFrame.new($form, transparent_image, LAYOUT_EXPLICIT, 280, 289, 26, 26)
#green_button.connect(SEL_LEFTBUTTONPRESS) {|sender, selector, data| $cursor_color = 0; $cursor.image = $color_image[$cursor_color]; puts "Green" }
#green_button.show()
#
#$form.connect(SEL_MOTION) { |sender, selector, data|
#  $cursor.position(sender.cursorPosition[0], sender.cursorPosition[1], 26, 26)
#  puts "move"
#}
#board.connect(SEL_MOTION) { |sender, selector, data|
#  $cursor.position(sender.cursorPosition[0], sender.cursorPosition[1], 26, 26)
#  puts "move"
#}
#
##main = application.addChore { |sender, sel, ptr|
##
##  puts "a"
##}
#
#
#application.create()
#$form.show(PLACEMENT_SCREEN)
#$form.enable()
#
#application.run()

