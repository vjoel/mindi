require 'mindi'

class Transformer
  def transform string
    string.gsub(pattern, &replacement)
  end
end

class TransformerContainer
  include MinDI::InjectableContainer

  pattern     { /foo/ }
  replacement { proc {|match| match.upcase } }
  transformer { Transformer.new }
  transform   { |str| transformer.transform(str) }
end

cont = TransformerContainer.new
s1 = cont.transform("fo foo fee")
s2 = cont.transform("fo foo fee")
p s1              # ==> "fo FOO fee"
p s1.equal?(s2)   # ==> true

__END__

Here's what happens when the service is instantiated (i.e. the "{
Transformer.new }" block is called in response to the #transformer
method on the container):

The service object (the Transformer instance returned by the block) is
given an instance variable, @__injectable__object__, whose value is set
to the container.

Also, the service object is extended, but only with a fairly minimal
module called Injected:

  module Injected
    def method_missing(*args, &block)
      @__injectable__object__ || super
      @__injectable__object__.send(*args, &block)
    rescue NoInjectedMethodError
      super
    end
  end

The NoInjectedMethodError is raised by the container's own
method_missing. So the method search order for the service object is:

1. the service object itself (the Transformer instance)

2. other services in the container (this is how "replacement" and
"pattern" are resolved)

3. method_missing, as defined in the ancestry of the service object
