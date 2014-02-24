$LOAD_PATH << './'

require 'fox16'
require 'fox16/colors'
include Fox
require 'net/ftp'

class MainWindow < FXMainWindow
  attr_accessor :img

  def initialize(application)
    super(application, "Visual", :opts => DECOR_ALL, :x => 0, :y => 0, :width => 475, :height => 200)
    self.layoutHints = LAYOUT_EXPLICIT

    @input_r = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 10, 10, 45, 23)
    @input_r.layoutHints = LAYOUT_EXPLICIT
    @input_g = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 55, 10, 45, 23)
    @input_g.layoutHints = LAYOUT_EXPLICIT
    @input_b = FXTextField.new(self, 40, nil, 0, TEXTFIELD_NORMAL, 100, 10, 45, 23)
    @input_b.layoutHints = LAYOUT_EXPLICIT

    @button_fill = FXButton.new(self, 'Fill', nil, nil, 0, BUTTON_NORMAL, 151, 10, 75, 23)
    @button_fill.layoutHints = LAYOUT_EXPLICIT

    @button_fill.connect(SEL_COMMAND) { |sender, selector, data|
      fill(@input_r.text.to_i, @input_g.text.to_i, @input_b.text.to_i)
    }

    @button_shade = FXButton.new(self, 'Shade', nil, nil, 0, BUTTON_NORMAL, 236, 10, 75, 23)
    @button_shade.layoutHints = LAYOUT_EXPLICIT

    @button_shade.connect(SEL_COMMAND) { |sender, selector, data|
      shade()
    }

    @button_noise = FXButton.new(self, 'Noise', nil, nil, 0, BUTTON_NORMAL, 321, 10, 75, 23)
    @button_noise.layoutHints = LAYOUT_EXPLICIT

    @button_noise.connect(SEL_COMMAND) { |sender, selector, data|
      noise(10)
    }

    @button_meltdown = FXButton.new(self, 'Wash', nil, nil, 0, BUTTON_NORMAL, 406, 10, 75, 23)
    @button_meltdown.layoutHints = LAYOUT_EXPLICIT

    @button_meltdown.connect(SEL_COMMAND) { |sender, selector, data|
      wash(10)
    }

    @img = FXImage.new(getApp(), nil, IMAGE_OWNED|IMAGE_DITHER|IMAGE_SHMI|IMAGE_SHMP, 240, 120)
    @frame_image = FXImageFrame.new(self, @img, FRAME_SUNKEN, 10, 33, 240, 120)
    @frame_image.layoutHints = LAYOUT_EXPLICIT

    fill(93, 13, 44)
  end

  def fill(r, g, b)
    r = 0 if r < 0 || r > 255
    g = 0 if g < 0 || g > 255
    b = 0 if b < 0 || b > 255

    @img.restore
    (0..239).each { |x|
      (0..119).each { |y|
        @img.setPixel(x, y, Fox.FXRGB(r, g, b))
      }
    }
    @img.render
    @frame_image.image = @img
    @frame_image.forceRefresh
    self.forceRefresh
  end

  def shade()
    @img.restore
    (0..239).each { |x|
      (0..119).each { |y|
        if x == 0
          lx = 0
        else
          lx = x - 1
        end
        last_color = @img.getPixel(x, y)
        actual_color = @img.getPixel(lx, y)
        last_r = Fox.FXREDVAL(last_color)
        last_g = Fox.FXGREENVAL(last_color)
        last_b = Fox.FXBLUEVAL(last_color)
        act_r = Fox.FXREDVAL(actual_color)
        act_g = Fox.FXGREENVAL(actual_color)
        act_b = Fox.FXBLUEVAL(actual_color)
        diff_r = (255 - last_r) / (240 - x)
        diff_g = (255 - last_g) / (240 - x)
        diff_b = (255 - last_b) / (240 - x)
        diff_r = 0 if act_r + diff_r > 255
        diff_g = 0 if act_g + diff_g > 255
        diff_b = 0 if act_b + diff_b > 255
        @img.setPixel(x, y, Fox.FXRGB((act_r + diff_r).to_i, (act_g + diff_g).to_i, (act_b + diff_b).to_i))
      }
    }
    @img.render
    @frame_image.image = @img
    @frame_image.forceRefresh
    self.forceRefresh
  end

  def noise(amount)
    @img.restore
    (0..239).each { |x|
      (0..119).each { |y|
        actual_color = @img.getPixel(x, y)
        act_r = Fox.FXREDVAL(actual_color)
        act_g = Fox.FXGREENVAL(actual_color)
        act_b = Fox.FXBLUEVAL(actual_color)
        if Random.rand(1) == 0
          r = act_r - Random.rand(Random.rand(amount) + 1)
        else
          r = act_r + Random.rand(Random.rand(amount) + 1)
        end
        if Random.rand(1) == 0
          g = act_g - Random.rand(Random.rand(amount) + 1)
        else
          g = act_g + Random.rand(Random.rand(amount) + 1)
        end
        if Random.rand(1) == 0
          b = act_b - Random.rand(Random.rand(amount) + 1)
        else
          b = act_b + Random.rand(Random.rand(amount) + 1)
        end
        r = 0 if r < 0
        g = 0 if g < 0
        b = 0 if b < 0
        r = 255 if r > 255
        g = 255 if g > 255
        b = 255 if b > 255
        @img.setPixel(x, y, Fox.FXRGB(r, g, b))
      }
    }
    @img.render
    @frame_image.image = @img
    @frame_image.forceRefresh
    self.forceRefresh
  end

  def wash(amount)
    @img.restore
    (0..239).each { |x|
      (0..119).each { |y|
        if Random.rand(2) == 0
          lx = x + amount * 2
          lx = 0 if lx > 239
        else
          lx = x + Random.rand(amount * 2) + amount
          lx = 0 if lx > 239
        end
        if Random.rand(2) == 0
          ly = y - amount
          ly = 0 if ly < 0
        else
          ly = y - Random.rand(amount)
          ly = 0 if ly < 0
        end
        last_color = @img.getPixel(lx, ly)
        last_r = Fox.FXREDVAL(last_color)
        last_g = Fox.FXGREENVAL(last_color)
        last_b = Fox.FXBLUEVAL(last_color)
        @img.setPixel(x, y, Fox.FXRGB(last_r, last_g, last_b))
      }
    }
    @img.render
    @frame_image.image = @img
    @frame_image.forceRefresh
    self.forceRefresh
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    enable()
  end
end

if __FILE__ == $0
  $application = FXApp.new("Visual", "gabor.major@csn.hu")
  MainWindow.new($application)
  $application.create
  $application.run
end