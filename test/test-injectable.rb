require 'minitest/autorun'
require 'mindi'

class Test_Injected < Minitest::Test
  # If there is no container, the normal method_missing should be used.
  def test_no_cointainer
    injected = Object.new
    injected.extend MinDI::Injectable::Injected
    
    def injected.method_missing(m, *args)
      args[0]
    end
    
    val = "Yep, that's it"
    assert_equal(val, injected.foobar(val))
  end
end


class Test_Injectable < Minitest::Test
  def test_inject_into
    injectable = Object.new
    injectable.extend MinDI::Injectable
    
    def injectable.foo
      :foo
    end
    
    injected = Object.new
    injectable.inject_into injected
    
    assert_equal(injectable.foo, injected.foo)
  end

  def test_non_non_unique_container
    injectable = Object.new
    injectable.extend MinDI::Injectable
    
    injectable2 = Object.new
    injectable2.extend MinDI::Injectable
    
    injected = Object.new
    injectable.inject_into injected
    assert_raises(MinDI::Injectable::NonUniqueContainerError) do
      injectable2.inject_into injected
    end
  end
end
