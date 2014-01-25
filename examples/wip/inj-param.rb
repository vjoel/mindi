require 'mindi'

class C
  include MinDI::InjectableContainer

#  uninjected
  foo { |x,y| (x + y).to_s }
end

cont = C.new

p cont.foo(1,2).foo(2,3)
