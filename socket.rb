#!/usr/bin/env ruby
=begin 

Socket.rb will listen for the map page's creation of a websocket. Once it's 
found it, it will then start listening for the tweetstream.rb script bunny message feed
and send the tweet location and body to the map page. 

Things I wanna do:

1. language specification on map page. This will send a message back to socket, which will
route the command to tweetstream, which will stop current collection and restart with new 
parameters.
2. Geolocation. Ideally, it would work like this: Click on 'Draw collection box', then
drag pointer to create a rectangle over a particular area of the world. The bounding box 
coordinates would then be passed to socket.rb and then to tweetstream, which would
report only on geotagged tweets within that area.
3. Geo-independent collection. This would work like...hmm. If you've toggled 'from wherever' 
it would still continue marking geotagged tweets on map, but non-geotagged would still be 
saved to a file (along with the rest). A counter somewhere would list a running tally of
tweets collected.
4. Keyword search, would work in same manner as language spec in terms of interprocess
communication.

=end

require 'em-websocket'
require 'uuid'
require 'bunny'

#cq = ch.queue("command")
#tq = ch.queue("tweets")
EM.run {
  EM::WebSocket.run(:host => "127.0.0.1", :port => 8567) do |ws|
  #EM::WebSocket.run(:host => "127.0.0.1", :port => 8080) do |ws|
    ws.onopen do
      puts "WebSocket opened"
      conn = Bunny.new
      conn.start
      ch = conn.create_channel
      ch.queue("tweets").subscribe do |delivery_info, properties, body|
        puts "Received tweet\n"
        encoded_tweet=body.force_encoding("iso-8859-1").force_encoding("utf-8")
        puts encoded_tweet
        ws.send encoded_tweet
      end
    end
    ws.onclose do
      ws.close(code = nil, body = nil)
      puts "WebSocket closed"
      exit
    end
  end
}
