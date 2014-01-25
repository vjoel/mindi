# Examples and unit tests (sort of) for MinDI.

require 'mindi'

class Foo; end
class Bar < Struct.new(:key); end
class Point < Struct.new(:x, :y); end

class MyContainer
  include MinDI::BasicContainer

  singleton :foo do
    Foo.new
  end

  # shortcut for singleton
  other_foo { Foo.new }

  multiton :bar_for do |key|
    Bar.new(key)
    # The Bar instance doesn't have to receive the key, but it can.
  end

  # shortcut for multiton
  other_bar_for { |key| Bar.new(key) }

  # shortcut for multiton with multiple keys
  point_for_xy { |x,y| Point.new(x,y) }

  # Reference other services.
  foos { [foo, other_foo] }

  # We can manage services manually.
  generic :gene do
    @gene ||= Foo.new
  end

  # service implementations are closures
  shared_foo = nil
  generic :shared do
    shared_foo ||= Foo.new
      # shared among all MyContainer instances
  end

  threaded :per_thread do # |thread| # optional
    Array.new
  end

  deferred :lazy do
    $deferred_service_done = true # for testing
    "Deferred service result"
  end

  begin
    not_a_service
  rescue NameError
    # Raises an error because no block is given, so it can't possibly be
    # a service definition. We just let the superclass's method_missing
    # handle it.
  else raise
  end
end

MyContainer.service_declared_outside do
  Bar.new(other_foo) # note scope is still the container instance
end

cont = MyContainer.new

raise unless cont.foo.equal?(cont.foo)
raise unless cont.other_foo.equal?(cont.other_foo)

raise unless cont.bar_for(3).equal?(cont.bar_for(3))
raise unless cont.other_bar_for(3).equal?(cont.other_bar_for(3))
raise unless cont.point_for_xy(3, 33).equal?(cont.point_for_xy(3, 33))

raise if cont.bar_for(3).equal?(cont.bar_for(7))
raise if cont.other_bar_for(3).equal?(cont.other_bar_for(7))
raise if cont.point_for_xy(3, 33).equal?(cont.point_for_xy(7, 77))

raise unless cont.foos.uniq.size == 2

raise unless cont.gene.is_a?(Foo)
raise unless cont.gene.equal?(cont.gene)

cont2 = MyContainer.new
raise unless cont2.shared.equal?(cont.shared)

raise unless cont.service_declared_outside.is_a?(Bar)

t1 = Thread.new { cont.per_thread }
t2 = Thread.new { cont.per_thread }

raise if t1.value.equal?(t2.value)

lazy = cont.lazy
raise if $deferred_service_done

lazy.grep /foo/ # Call a method, which will instantiate the object.
raise unless $deferred_service_done

# The container class may accept perameters for instantiating containers.
class ParametricContainer
  include MinDI::InjectableContainer
  def initialize(name, opts = {})
    @name = name
    @opts = opts
  end

  thing { @opts[:thing_class].new("thing of #{@name}") }
end

tc = Struct.new(:name)
pc = ParametricContainer.new("fred", {:thing_class => tc})
raise unless pc.thing.name == "thing of fred"

puts "all tests passed!"
