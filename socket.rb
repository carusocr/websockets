#!/usr/bin/env ruby
#look into websocket client
# https://github.com/mwylde/em-websocket-client

require 'em-websocket'
require 'uuid'
require 'bunny'

conn = Bunny.new
conn.start
ch = conn.create_channel
cq = ch.queue("command")
tq = ch.queue("tweets")
EM.run {
  EM::WebSocket.run(:host => "127.0.0.1", :port => 8567) do |ws|
  #EM::WebSocket.run(:host => "127.0.0.1", :port => 8080) do |ws|
    ws.onopen do
      puts "WebSocket opened"
#      conn = Bunny.new
#      conn.start
      q = ch.queue("tweets")
      q.subscribe(:block => true) do |delivery_info, properties, body|
        puts "Received tweet\n"
        encoded_tweet=body.force_encoding("iso-8859-1").force_encoding("utf-8")
        puts encoded_tweet
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
}
