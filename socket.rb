#!/usr/bin/env ruby
#look into websocket client
# https://github.com/mwylde/em-websocket-client

require 'em-websocket'
require 'uuid'
require 'bunny'

conn = Bunny.new
conn.start
ch = conn.create_channel
x = ch.default_exchange
cq = ch.queue("command")
tq = ch.queue("tweets")
x.publish("Testing command queue", :routing_key => cq.name)
sleep 1
x.publish("Testing tweet queue", :routing_key => tq.name)
sleep 1
x.publish("Testing command queue", :routing_key => cq.name)
sleep 1
x.publish("Testing tweet queue", :routing_key => tq.name)
sleep 1
conn.close
exit
EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen do
    puts "WebSocket opened"
    conn = Bunny.new
    conn.start
    #ch = conn.default_channel
    q = ch.queue("tweets")
    q.subscribe(:block => true) do |delivery_info, properties, body|
      puts "Received tweet\n"
      encoded_tweet=body.force_encoding("iso-8859-1").force_encoding("utf-8")
      ws.send encoded_tweet
    end
    q.publish("Test") 
  end
  ws.onclose do
    ws.close(code = nil, body = nil)
    puts "WebSocket closed"
    exit
  end
end
