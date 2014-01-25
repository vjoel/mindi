MinDI
=====

MinDI is Minimalist Dependency Injection for Ruby. It is inspired by Jamis Buck's Needle (http://needle.rubyforge.org) and Jim Weirich's article on DI in Ruby (http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc).

MinDI is minimalist in that it attempts to map concepts of DI into basic ruby
constructs, rather than into a layer of specialized constructs. In particular, classes and modules function as containers and registries, and methods and method definitions function as service points and services. There are some inherent advantages and disadvantages to this approach, discussed below.

MinDI builds on this minimal DI container by adding the InjectableContainer concept, which is a kind of DI available only in dynamic languages: through the magic of <tt>method_missing</tt>, a service may invoke other services without having explicit setter or constructor references to those services.

Synopsis
--------

Using the BasicContainer module for constructor injection:

    require 'mindi'

    class SimpleContainer
      include MinDI::BasicContainer

      greeting { "Hello, world\n" }

      point_at { |x,y| [x,y] }

      stuff { [greeting, point_at(100,200)] }
    end

    cont = SimpleContainer.new

    p cont.stuff   # ==> ["Hello, world\n", [100, 200]]

Using the InjectableContainer module for "dynamic" or "fallback" injection, using `method_missing`:

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


Note that the Transformer class is written without explicitly linking up
to services (either in initialize or in setters). It just assumes that
the services will be defined in the container.

Note also that the #transform service is a multiton service, and (like
singleton services) it caches its value for each argument.


Advantages
----------

- Compact implementation (the essentials are about 100 lines).

- Compact syntax.

- Familiar constructs and idioms, like subclassing, module inclusion, nested
  classes, protected and private, all apply.

- Use of classes and methods as containers and services means you can apply a
  standard AOP or debugging lib.

- Services can take arguments, and this permits multiton services. Like singleton services, multiton services cache their results.

- Dynamic service registration is easy, since ruby's class system is itself
  so dynamic. See examples/dynamic.rb.

Disadvantages
-------------

- A container's services live in the same namespace as the methods inherited
  from Kernel and Object, so a service called "dup", for example, will
  prevent calling Object#dup on the container (except in the implementation
  of the dup service, which can use super to invoke Object#dup). The MinDI
  framework itself adds a few methods that could conflict with services
  (#singleton, #generic, etc.). Also, the "shortcut" service definition
  (using method_missing) will not let you define services like "dup"--you
  would have to use an explicit definer, like #singleton.

- No built-in AOP, logging, debugging, or reflection interface, as in Needle.

Notes
-----

- Supports threaded, deferred, singleton, and multiton service models (though
  these are not yet independent choices). Additional service models can be
  easily added in modules which include Container. The "generic" model can
  be used like "prototype" in Needle, or for manual service management.

- Use mixins to build apps out of groups of services that need to coexist in
  one name space.

- Use a nested class for a group of services when you want them to live in
  their own namespace. (See the ColorNamespace example.)

- The Injectable module can be used without MinDI containers as a kind of
  delegation:

      require 'mindi'
      x = [1,2,3]
      y = {}
      x.extend MinDI::Injectable
      x.inject_into y
      p y.reverse    # ==> [3, 2, 1]

- MinDI can be used as a Rake-like task scheduler:

```
      require 'mindi'
      
      class Tasks
        include MinDI::BasicContainer
        
        a  { print "a" }
        b  { a; print "b" }
        c  { a; print "c" }
        d  { b; c; print "d" }
      end
      
      Tasks.new.d  # ==> abcd 
```

Bugs
----

- Private and protected services must be declared explicitly:

      private :some_service

  rather than by putting them in the private section of the class def.

- Because of how ruby defines Proc#arity, a service defined like

      sname { do_something }

  with no argument list will be treated as a multikey_multiton rather than
  as a singleton. The behavior will be the same, though.

- Running ruby with the -w option will warn about 'instance variable @foo not
  initialized'.

Todo
----

- MinDI had some introspection methods ("services_by_model(m)"), but I took
  them out to keep the lib minimal. Maybe they will be in a mixin later.

- Use args passed to service point declarations to specify aspects of the
  service model (e.g., threaded and deferred could be specified this way).

- DRb services and distributed containers. Use Rinda for service discovery.

- Thread safety issues.

Legal and Contact Information
-----------------------------

Copyright (C) 2004-2014 Joel VanderWerf, mailto:vjoel@users.sourceforge.net.

License is BSD. See [COPYING](COPYING).
