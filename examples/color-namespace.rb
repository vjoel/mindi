# Namespace example

require 'mindi'

class PictureApp
  include MinDI::InjectableContainer

  class Picture
    attr_reader :opts
    def initialize(opts)
      @opts = opts
    end
  end

  class Color < Struct.new(:r, :g, :b)
    def +(color)
      Color.new(r + color.r, g + color.g, b + color.b)
    end
  end

  class ColorNamespace
    include MinDI::InjectableContainer

    red     { Color.new(1,0,0) }
    green   { Color.new(0,1,0) }
    yellow  { red + green      }
  end

  colors  { ColorNamespace.new }
  picture { Picture.new(:background => colors.yellow) }
end

pic_app = PictureApp.new
pic = pic_app.picture
raise unless pic.opts[:background] == pic_app.colors.yellow

