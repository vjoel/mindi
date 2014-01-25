module MinDI  # :nodoc:
  # Extend a class (or module) with Container to make the class behave as a
  # class of service containers. Containers encapsulate the way in which related
  # services are instantiated and connected together. Services themselves are
  # insulated from this process [except when they are injected with the
  # container].
  #
  # Use MinDI by <b><tt>include</tt></b>ing the MinDI::InjectableContainer
  # module in your container class. As of version 0.2, this does two things: it
  # <b><tt>extend</tt></b>s your container class with the Container module,
  # which provides class methods for expressing service definitions in a
  # natural, rubylike way. It also injects the container into all services which
  # gives them direct access to the other services in the container. If you
  # prefer to have the container funtionality without injecting services (i.e.,
  # just "contructor injection") You can just include MinDI::BasicContainer.
  #
  # The Container module also defines shortcuts for defining some service types
  # using +method_missing+. These methods and shortcuts are described below.
  #
  # A service definition involves a service name and a block of code. It defines
  # an instance method whose name is the service name. The block is used to
  # instantiate the service. When and how that service is instantiated depends
  # on the type of service.
  #
  # <i>Note:</i> MinDI uses some instance variables and auxiliary instance
  # methods in the container. The instance variables have the same name as the
  # corresponding services, possibly with added suffixes, as in the case of
  # #deferred. The auxiliary methods are named so as to make conflicts unlikely.
  # See the implemetations of #iv and #impl_method_name for details.
  #
  # Note that services can be defined dynamically by reopening the class scope
  # or simply by calling the service with a block. See examples/dynamic.rb.

  VERSION = '0.5'

  module Container
  
    # ------------------------
    # :section: Basic services
    #
    # Methods which define a service in terms of simple rules involving
    # existence, uniqeness, and parameters.
    # ------------------------
    
    # Define a generic service, which has no built-in rules for existence or
    # uniqueness. There is no shortcut for generic service definition. Calling
    # the service simply calls the associated block. This is also known as a
    # _prototype_ service.
    
    def generic(name, &impl)  # :yields:
      define_implementation(name, impl)
    end

    # Define a singleton service:
    #
    #   singleton(:service_name) { ... }
    #
    # The block will be called at most once to instantiate a unique value
    # for the service. The shortcut for defining a singleton is:
    #
    #   service_name { ... }
    #
    # The service is invoked as <tt>service_name</tt>.
    
    def singleton(name, &impl)  # :yields:
      impl_name = Container.impl_method_name(name)
      define_implementation(impl_name, impl)

      ivname = Container.iv(name)
      define_method(name) do
        box = instance_variable_get(ivname)
        box ||= instance_variable_set(ivname, [])
        box << send(impl_name) if box.empty?
        box.first
      end
    end
    
    # Define a multiton service:
    #
    #   multiton(:service_name) { |arg| ... }
    #
    # The block will be called once per distinct (in the sense of hash keys)
    # argument to instantiate a unique value corresponding to the argument. The
    # shortcut for defining a multiton is:
    #
    #   service_name { |arg| ... }
    #
    # The service is invoked as <tt>service_name(arg)</tt>.
    
    def multiton(name, &impl) # :yields: arg
      impl_name = Container.impl_method_name(name)
      define_implementation(impl_name, impl)
      
      ivname = Container.iv(name)
      define_method(name) do |key|
        map = instance_variable_get(ivname)
        map ||= instance_variable_set(ivname, {})
        map.key?(key) ?  map[key] : map[key] = send(impl_name, key)
      end
    end
    
    # Define a multiton service with multiple keys:
    #
    #   multiton(:service_name) { |arg0, arg1, ...| ... }
    #
    # The block will be called once per distinct (in the sense of hash keys)
    # argument list to instantiate a unique value corresponding to the argument
    # list. The shortcut for defining a multikey_multiton with multiple keys is:
    #
    #   service_name { |arg0, arg1, ...| ... }
    #
    # The service is invoked as <tt>service_name(arg0, arg1, ...)</tt>.
    # Variable length argument lists, using the splat notation, are permitted.
    
    def multikey_multiton(name, &impl) # :yields: arg0, arg1, ...
      impl_name = Container.impl_method_name(name)
      define_implementation(impl_name, impl)

      ivname = Container.iv(name)
      define_method(name) do |*key|
        map = instance_variable_get(ivname)
        map ||= instance_variable_set(ivname, {})
        map.key?(key) ?  map[key] : map[key] = send(impl_name, *key)
      end
    end
    
    # ---------------------------
    # :section: Advanced services
    # 
    # Methods which define a service in terms of more complex modalities, such
    # as per-thread uniqueness, and deferred, on-demand existence.
    # ---------------------------
    
    # Define a service with per-thread instantiation. For each thread, the
    # service appears to be a singleton service. The block will be called at
    # most once per thread. There is no shortcut. The block may take a single
    # argument, in which case it will be passed the current thread.
    #
    #   threaded(:service_name) { |thr| ... }
    
    def threaded(name, &impl)  # :yields: thr
      impl_name = Container.impl_method_name(name)
      define_implementation(impl_name, impl)
      arity = impl.arity

      ivname = Container.iv(name)
      define_method(name) do
        key = Thread.current
        map = instance_variable_get(ivname)
        map ||= instance_variable_set(ivname, {})
        map[key] ||= (arity == 1 ? send(impl_name, key) : send(impl_name))
      end
    end
    
    PROXY_METHODS = ["__send__", "__id__", "method_missing", "call"] # :nodoc:
    
    # Define a singleton service with deferred instantiation. Syntax and
    # semantics are the same as #singleton, except that the block is not called
    # when the service is requested, but only when a method is called on the
    # service.
    
    def deferred(name, &impl)  # :yields:
      impl_name = Container.impl_method_name(name)
      define_implementation(impl_name, impl)
      
      proxy_name = Container.impl_method_name("#{name}_proxy")

      ivname = Container.iv(name)
      proxy_ivname = Container.iv("#{name}_proxy")
      
      define_method(name) do
        instance_variable_get(ivname) || send(proxy_name)
      end
      
      define_method(proxy_name) do
        proxy = instance_variable_get(proxy_ivname)
        
        unless proxy
          proxy = proc {instance_variable_set(ivname, send(impl_name))}
          def proxy.method_missing(*args, &block)
            call.__send__(*args, &block)
          end
          instance_variable_set(proxy_ivname, proxy)
          class << proxy; self; end.class_eval do
            (proxy.methods - PROXY_METHODS).each do |m|
              undef_method m
            end
          end
        end

        proxy
      end
    end
    
    # ---------------------------
    # :section: Internal methods
    # ---------------------------
    
    # For declarative style container definitions ("shortcuts").
    def method_missing(meth, *args, &bl) # :nodoc:
      super unless bl

      case bl.arity
      when 0
        singleton(meth, *args, &bl)
      when 1
        multiton(meth, *args, &bl)
      else
        # note that this includes the case of a block with _no_ args, i.e.
        # { value }, which has arity -1, indistinguishabe from {|*args|}.
        multikey_multiton(meth, *args, &bl)
      end
    end
   
  protected
    def define_implementation impl_name, impl
      if @__services_are_injected__
        preinject_method = impl_name + "__preinject"
        define_method(preinject_method, &impl)
        define_method(impl_name) do |*args|
          inject_into send(preinject_method, *args)
        end
      else
        define_method(impl_name, &impl)
      end
    end

    # The name of an instance variable that stores the state of the service
    # named _name_.
    def self.iv(name) # :doc:
      "@___#{name}___value"
    end
    
    # The name of a method used internally to implement the service named
    # _name_.
    def self.impl_method_name(name) # :doc:
      "___#{name}___implementation"
    end
    
  end
  
  # Include this in a container class to allow use of #inject_into within
  # services. See examples/inject.rb. Including this module also extends the
  # class with the Container module, so a simple shortcut to making a fully
  # functional injectable container is to simply include Injectable.
  #
  # This module can be used outside of the context of MinDI::Container: almost
  # any object can be injected into any other. For example:
  #
  #    x = [1,2,3]
  #    y = {}
  #    x.extend MinDI::Injectable
  #    x.inject_into y
  #    p y.reverse      => [3, 2, 1]
  #
  # Note that injecting an Injectable object into another object never
  # interferes with methods of the latter object.
  #
  # Note that injected methods operate on the injecting instance, not the
  # injectee. So instance variables...
  #
  # Note similarity to Forwardable and Delegator in the stdlib. However,
  # Injectable is more passive in that (as noted above) it only affects the
  # handling of methods that are _missing_ in the target object. In that
  # respect, Injectable is a little like inheritance (except as noted above
  # about which instance is operated on).
  module Injectable
    # Raised and rescued internally to pass _method_missing_ back from container
    # to service object. Client code should not have to handle this exception.
    class NoInjectedMethodError < StandardError; end
    
    # Raised on attempt to add object to a second container.
    class NonUniqueContainerError < StandardError; end
    
    # Internally used to extend service objects so that they can delegate sevice
    # requests to their container.
    #
    # This module can be included explicitly in the class of the service
    # objects. For most purposes there is no reason to do so. However, if an
    # object is dumped and re-loaded with YAML, it will lose track of modules
    # that it has been extended with. By including the module in the class, the
    # loaded object will have the right ancestors. (Marshal does not have this
    # limitation.)
    #
    # An object can be injected with at most one Injectable object at a time.
    #
    # The implementation of Injected is essentially <tt>extend</tt>-ing with a
    # module that has a <tt>method_missing</tt>.
    module Injected
      # Delegates to the Injectable object any method which it must handle. If
      # the Injectable object does not handle the method, or if there is no
      # Injectable object assigned to self, then self's own _method_missing_ is
      # called.
      def method_missing(*args, &block)
        @__injectable__object__ || super
        @__injectable__object__.send(*args, &block)
      rescue NoInjectedMethodError
        super
      end
    end

    # Inject the container's services into _obj_. The service methods can be
    # called from within the object's methods, and they will return the same
    # objects as if they were called from the container.
    #
    # Returns _obj_, so that the method can be called within service
    # definitions.
    #
    def inject_into obj
      begin
        obj.extend Injected
      rescue TypeError
        warn "#{caller[2]}: warning: class #{obj.class} cannot be injected into"
        return obj
      end

      cont = obj.instance_variable_get(:@__injectable__object__)
      if cont and cont != self
        raise NonUniqueContainerError,
          "Object #{obj.inspect} already belongs to #{cont.inspect}." +
          " Was attempting to inject #{self.inspect} into it."
      end
      
      obj.instance_variable_set(:@__injectable__object__, self)
      obj
    end
  
    def method_missing(m, *rest) # :nodoc:
      raise NoInjectedMethodError
    end
  end
  
  # For convenience, so that you can use 'include MinDI::BasicContainer' rather
  # than 'extend MinDI::Container'.
  module BasicContainer
    def self.included mod # :nodoc:
      mod.extend Container
    end
  end

  # An InjectableContainer "injects" itself into the services, so that they
  # can all refer to each other.
  #
  # Including this module has the combined effect of making the class act as a
  # container (by *extend*-ing it with Container) and making the class
  # Injectable (by *include*-ing Injectable). Additionally, including this
  # module defines two class methods #injected and #uninjected, which determine
  # whether subsequently defined services have the container injected into them.
  # (The default is #injected.)
  #
  # Also, the module defines an #inspect method, so that inspecting injected
  # objects doesn't dump the entire container and all of its services.
  #
  module InjectableContainer
    include Injectable
    
    # These methods are available in the scope of your class definition, after
    # you have included MinDI::InjectableContainer.
    module ClassMethods
      # Set state so subsequently defined services have the container injected
      # into them when they are instantiated. (This is the default state.)
      def injected
        @__services_are_injected__ = true
      end
      
      # Set state so subsequently defined services do not have the container
      # injected into them when they are instantiated.
      def uninjected
        @__services_are_injected__ = false
      end
    end

    def self.included mod # :nodoc:
      mod.extend Container
      mod.extend InjectableContainer::ClassMethods
      mod.injected
    end
    
    def inspect # :nodoc:
      "<#{self.class}:0x%0x>" % object_id
    end
  end
end
