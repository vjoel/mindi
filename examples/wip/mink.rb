# a make/rake type tool using MinDI

require 'mindi'

module Mink
  include MinDI::Container
  
#  def task(t, &bl)
#    task_impl = "task_#{t}"
#    
#    case bl.arity
#    when 0, -1
#      define_method(task_impl, &bl)
#      singleton(t) do
#        ##ivname = Container.iv(name)
#        ##if instance_variable_get(ivname)
#        ## raise if value is :in_progress
#        ## set value to :in_progress
#        result = send(task_impl)
#        result || true
#      end
#    
#    when 1
#      define_method(task_impl, &bl)
#      multiton(t) do |arg|
#        ##ivname = Container.iv(name)
#        ##if instance_variable_get(ivname)
#        ## raise if value is :in_progress
#        ## set value to :in_progress
#        result = send(task_impl, arg)
#        result || true
#      end
#      
#    else
#      raise "arity == #{bl.arity}"
#    end
  end
end

class C
  extend Mink
  
  # print each string at most once
  output do |s| puts s end
  
  z do output "bar" end
  a do z; output "bar" end
  b do a end
  c do a end
  d do b; c; "d is done" end
  
  xa  { puts "xa" }
  xb  { xa; puts "xb" }
  xc  { xa; puts "xc" }
  xd  { xb; xc; puts "xd" }
end

p C.new.xd
