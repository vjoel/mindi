require 'mindi'

Parser = Struct.new :game # add parser state vars here
Player = Struct.new :game, :location, :contents
World = Struct.new :game # add state vars (:time, maybe)
Map = Struct.new :game
  # The :game attr is useful if you want to write methods of
  # these classes (Player for example) that refer to the other
  # game objects. But it's not strictly necessary.

Room = Struct.new :name, :contents

# Sometimes, a struct is not enough...
class Thing
  attr_accessor :name
  attr_reader :location

  def initialize name, location = nil
    @name = name
    @location = location
  end
  
  # Moving a Thing updates the Room it's in or Player who has it
  def location=(loc)
    @location.contents.delete self if @location
    @location = loc
    @location.contents << self if @location
  end
end

class GameContainer
  include MinDI::InjectableContainer
  
  # These are some singletons--one instance each.
  parser  { Parser.new self }
  player  { Player.new self, start_room, [] }
  world   { World.new self }
  map     { Map.new self }
  
  # A multiton.
  # The |name| means there can be many things--one for each name.
  # internally, there is a hash  stored in @thing that maps
  # each name strign to a Thing.
  thing { |name| Thing.new name }

  # The shovel (unique with that name).
  shovel { thing "Shovel" }

  room { |name| Room.new name, [] }

  start_room { room "garden" }
  
  # Set up some initial conditions
  def initialize
    # create and locate the shovel
    shovel.location = start_room
  end
end

game = GameContainer.new

# The shovel is already defined:
p game.shovel
puts

# Create a new thing:
ball = game.thing("ball")
ball.location = game.room "basement"
p ball
puts

player = game.player

# pick up the shovel and anything else in the start room
# This could be made into a #pick_up method of Game or of Player
player.location.contents.each { |thing| thing.location = player }
p player.contents.map {|thing| thing.name}
puts

# move the player
p player.location.name
player.location = game.room "basement"
p player.location.name
puts

# get the ball
player.location.contents.each { |thing| thing.location = player }
p player.contents.map {|thing| thing.name}
puts

# You can define new methods on the GameContainer that access the internal
# storage used by the "service" methods.
class GameContainer
  def rooms
    instance_variable_get(MinDI::Container.iv("room")).values
    # because internally the "room" service uses a hash stored in
    # an instance var with a munged name
  end
  
  def things
    instance_variable_get(MinDI::Container.iv("thing")).values
  end
end

# Show all the rooms
p game.rooms

# Show all the things
p game.things.map {|thing| thing.name}

__END__

Output:

#<Thing:0xb7d862fc @name="Shovel", @location=#<struct Room name="garden", contents=[#<Thing:0xb7d862fc ...>]>>

#<Thing:0xb7d85078 @name="ball", @location=#<struct Room name="basement", contents=[#<Thing:0xb7d85078 ...>]>>

["Shovel"]

"garden"
"basement"

["Shovel", "ball"]

[#<struct Room name="garden", contents=[]>, #<struct Room name="basement", contents=[]>]
["ball", "Shovel"]
