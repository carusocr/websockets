#!/usr/bin/env ruby
#look into websocket client
# https://github.com/mwylde/em-websocket-client
# troubleshooting socket.rb: socket and tweetstream communicate, but map doesn't get msgs

require 'em-websocket'
require 'bunny'

conn = Bunny.new
conn.start
ch = conn.create_channel
tq = ch.queue("tweets")

#=begin
#THIS WORKS AND GENERATES AN ALERT IN MAP.HTML

EM.run {
  EM::WebSocket.run(:host => "127.0.0.1", :port => 8567) do |ws|
    ws.onopen do
      puts "WebSocket opened"
      ws.send "test"
      #commenting this out allows test to go through, uncommenting prevents. ?!?
      #tq.subscribe(:block=>true) do |delinfo, properties, body|
      #  puts "Got one! Sending test to map..."
      #  ws.send "test"
      #end
    end
    ws.onclose do
      ws.close(code = nil, body = nil)
      puts "WebSocket closed"
      exit
    end
  end
}
#=end
