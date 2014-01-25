require 'mindi'

class Tasks
  include MinDI::BasicContainer

  a  { print "a" }
  b  { a; print "b" }
  c  { a; print "c" }
  d  { b; c; print "d" }
end

Tasks.new.d

