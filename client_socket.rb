require 'socket'

s = UNIXSocket.new("/tmp/sock")
s.send "ZUG!", 0
