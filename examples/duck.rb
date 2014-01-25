# This is the basic idea of Injectable, without MinDI around it.

module Injectable
  module Injected
    def method_missing(*args, &block)
      @__injectable__container__ || super
      @__injectable__container__.send(*args, &block)
    rescue NoInjectedMethodError
      super
    end
  end

  def inject_into obj
    obj.extend Injected
    obj.instance_variable_set(:@__injectable__container__, self)
    obj
  end

  def method_missing(m, *rest)
    raise NoInjectedMethodError
  end
end

class Duck
  include Injectable
  
  def quack; @quack_behavior.quack; end
  def waddle; @waddle_behavior.waddle; end
  
  def initialize(h)
    @quack_behavior = h[:quack_behavior]
    @waddle_behavior = h[:waddle_behavior]
    
    inject_into @quack_behavior
    inject_into @waddle_behavior
  end
end

class StandardQuacker
  def quack
    puts "QUACK!"
  end
end

class NoisyWaddler
  def waddle
    quack       # note that this propagates to Duck then to quacker
    puts "<waddle>"
    quack
  end
end

duck = Duck.new(
  :quack_behavior   => StandardQuacker.new,
  :waddle_behavior  => NoisyWaddler.new
)

duck.waddle

__END__

Output:

QUACK!
<waddle>
QUACK!
