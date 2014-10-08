#!/usr/bin/env ruby

require 'socket'

`rm /tmp/sock`
UNIXServer.open("/tmp/sock") { |serv|
  while (s = serv.accept)
    if s.read == 'ZUG!'
      puts 'got one'
    end
  end
}
