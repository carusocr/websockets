#!/usr/bin/env ruby
#look into websocket client
# https://github.com/mwylde/em-websocket-client
# troubleshooting socket.rb: socket and tweetstream communicate, but map doesn't get msgs

require 'em-websocket'
require 'bunny'

conn = Bunny.new
conn.start
$ch = conn.create_channel
$tq = $ch.queue("tweets")

#=begin

def test1 #fails

  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8567) do |ws|
    ws.onopen do
      puts "WebSocket opened"
      conn = Bunny.new
      conn.start
#ch = conn.default_channel
      q = $ch.queue("tweets")
      q.subscribe(:block => true) do |delivery_info, properties, body|
       puts "Received tweet\n"
       ws.send "test"
      end
    end
    ws.onclose do
      ws.close(code = nil, body = nil)
      puts "WebSocket closed"
# exit
    end
  end
end

def test2 #fails with subscribe block...why?

  EM.run {
    EM::WebSocket.run(:host => "127.0.0.1", :port => 8567) do |ws|
      ws.onopen do
        puts "WebSocket opened"
        ws.send "test"
        #commenting this out allows test to go through, uncommenting prevents. ?!?
        # when I uncommented and ran this, got back two "Got one!" messages. 
        # Am I screwing up by using the tq and basically sending messages to myself? 
        # Bonehead mistake.
#        $tq.subscribe(:block=>true) do |delinfo, properties, body|
#          puts "Got one! Sending test to map..."
#          ws.send "test"
#        end
      end
      ws.onclose do
        ws.close(code = nil, body = nil)
        puts "WebSocket closed"
        exit
      end
      ws.onmessage do
        puts "Got reply message from map.html"
      end
    end
  }

end

test2
#=end
