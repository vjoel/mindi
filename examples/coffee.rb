# Coffee machine example taken from Jim Weirich's OSCON 2005 slides
# and rewritten in MinDI (following Christian Neukirchen).

require 'mindi'

class PotSensor
  def initialize(port)
    @port = port
  end

  def coffee_present?
    #...
  end
end

class MockSensor < PotSensor; end

class Heater
  def initialize(port)
    @port = port
  end

  def on
    #...
  end
  def off
    #...
  end
end

class MockHeater < Heater; end

class Warmer
  # Use attr_reader instead of "inject"--advantages: Warmer is
  # not dependent on DI framework, and the configuration of
  # the warmer is explicit in the container definition, below,
  # rather than using implicit, based on method names.
  attr_reader :pot_sensor, :heater
  
  def initialize(h)
    @pot_sensor = h[:pot_sensor]
    @heater = h[:heater]
  end
  
  def trigger
    if pot_sensor.coffee_present?
      heater.on
    else
      heater.off
    end
  end
end


class MarkIVConfiguration
  include MinDI::InjectableContainer
  
  uninjected # avoid warnings that "class Fixnum cannot be injected into"
  pot_sensor_io_port  {0x08F0}
  heater_io_port      {0x08F1}
  injected
  
  pot_sensor {PotSensor.new pot_sensor_io_port}
  heater {Heater.new heater_io_port}
  warmer {Warmer.new :heater => heater, :pot_sensor => pot_sensor}
  # IMO, it's better to keep this information in the container def.,
  # rather than "hide" it in the inject declarations in Warmer. Isn't
  # that more the spirit of DI?
end

class MarkIVTestConfig < MarkIVConfiguration
  heater {MockHeater.new}
  pot_sensor {MockSensor.new}
end

mkiv = MarkIVConfiguration.new
p mkiv.warmer
