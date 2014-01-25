require 'mindi'

#---------------
# Example showing how to use #inject_into to give a service object direct access
# to other services in the container, without having to explicitly reference
# the container object. See the GenericCopier#copy method and the #copier
# service. This further reduces the dependence of service classes on the
# structure of the container, since the initialize method of GenericCopier
# doesn't need to know about reader and writer (in fact you don't even need to
# write an initialize method in this case). The GenericCopier class can be
# tested with a mock reader and a mock writer by adding reader and writer
# methods.

module Acme
  class Scanner1200PDQ
    def read
      "this is some dummy text"
    end
  end
end

module FooCorp
  class LaserPrinter5
    def write(str)
      puts str
    end
  end
end

class GenericCopier
  def copy
    data = reader.read
    writer.write data
  end
end

class SimpleOffice
  include MinDI::InjectableContainer

  copier { GenericCopier.new }
  reader { Acme::Scanner1200PDQ.new }
  writer { FooCorp::LaserPrinter5.new }
end

office = SimpleOffice.new

office.copier.copy


#---------------
# This example shows that inject_into can be used to define mutually depedent
# services more conveniently. First, a mutual dependence example without using
# inject_into:

class A
  attr_accessor :b
  def initialize b
    @b = b
  end
end

class B
  attr_accessor :a
  def initialize a
    @a = a
  end
end

class MutualContainer
  include MinDI::BasicContainer

  a { temp_a = A.new(b); b.a = temp_a; temp_a }
    # awkward!
  
  b { B.new(nil) }
    # This still doesn't work properly! There's no way to refer to 'a' yet.
end

cont = MutualContainer.new
p cont.b.a # returns nil until after service 'a' is invoked
p cont.a.b.a.b
p cont.b.a # returns a

#---------------
# Next, a mutual dependence example using inject_into. Note how much
# simpler the service implementations are!

class A2
end

class B2
end

class MutualContainerUsingInjectable
  include MinDI::InjectableContainer

  a { A2.new }
  b { B2.new }
end

cont = MutualContainerUsingInjectable.new
p cont.b.a.b.a # everything is set up correctly
p cont.a.b.a.b


#---------------
# It is even possible to inject one _container_ into another:

class OuterContainer
  include MinDI::BasicContainer
  
  something { [:foo, "bar", something_else] }
    # note the reference to a service provided by the InnerContainer
end

class InnerContainer
  include MinDI::InjectableContainer
  
  injected # this is the default anyway
  outer { OuterContainer.new }

  uninjected
    # No need to mess up this little hash by injecting InnerContainer into it
  something_else { { :baz => :zap } }
end

ic = InnerContainer.new

p ic.outer.something


#---------------
# Using Injectable without MinDI containers.

x = [1,2,3]
y = {}
x.extend MinDI::Injectable
x.inject_into y
p y.reverse


