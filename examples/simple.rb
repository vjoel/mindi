require 'mindi'

class SimpleContainer
  include MinDI::BasicContainer

  greeting { "Hello, world\n" }
  
  point_at { |x,y| [x,y] }
  
  stuff { [greeting, point_at(100,200)] }
end

cont = SimpleContainer.new

p cont.stuff   # ==> ["Hello, world\n", [100, 200]]
