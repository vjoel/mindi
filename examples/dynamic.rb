require 'mindi'

# Shows how to register services dynamically; this is usually done
# with a "register" method in other DI frameworks, but we use method
# definition, because that can be done dynamically in ruby.

class DynamicContainer
  include MinDI::InjectableContainer
  
  stuff { [foo, bar] }  # foo and bar not defined yet
end

cont = DynamicContainer.new

# Add a service to DynamicContainer at service point foo.
DynamicContainer.foo {"FOO"}
p cont.foo    # ==> "FOO"

# Add a service just to the instance cont at service point bar.
class << cont; bar { "BAR" }; end
p cont.bar    # ==> "BAR"

# Now #stuff will work,
p cont.stuff  # ==> ["FOO", "BAR"]
