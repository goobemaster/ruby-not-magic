$LOAD_PATH << './'

require 'fox16'
include Fox

application = FXApp.new

icon = FXICOIcon.new(application, File.open("mastermind.ico", "rb").read(), 0, 0, 32, 32)
board_image = FXPNGImage.new(application, File.open("board.png", "rb").read(), 0, 316, 455)
color_image = Array.new()
(0..5).each { |i|
  color_image[i] = FXPNGImage.new(application, File.open("c#{i.to_s}.png", "rb").read(), 0, 16, 16)
}
board_image = FXPNGImage.new(application, File.open("board.png", "rb").read(), 0, 316, 455)

form = FXMainWindow.new(application, "Mastermind", icon, icon, DECOR_ALL, 0, 0, 316, 455)
form.backColor = Fox.FXRGB(255, 255, 255)

board = FXImageFrame.new(form, board_image, 0, 0, 0, 316, 455)
board.show

application.create()
form.show(PLACEMENT_SCREEN)

application.run()

