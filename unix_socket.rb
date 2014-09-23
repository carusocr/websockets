#!/usr/bin/env ruby

require 'socket'

UNIXServer.open("/tmp/sock") { |serv|
  while (s = serv.accept)
    puts s.read
  end
}
