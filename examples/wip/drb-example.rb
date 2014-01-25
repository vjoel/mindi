
#  class ContainerWithDRbObject
#    extend MinDI::Container
#    
#    server { #"druby://localhost:9000" }
#      require 'drb'
##      DRb.start_service(nil)
#      DRbObject.new(nil, "druby://localhost:9000")
#    }
#  end
#  
#  cwdo = ContainerWithDRbObject.new
#  p cwdo.server
#  cwdo.server.foo
