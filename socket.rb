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

Extra notes: I'm having trouble with using bunny for bidirectional communication. Brute
forcing process control by having the map.html send a 'restart' message and then having
socket.rb send a Process.kill command to tweetfeed and then restarting it with a new 
set of parameters may work. Got the kill part functional, test out the next step.o

** start playing with forking of child processes...this might be a good solution.

=end

require 'em-websocket'
require 'uuid'
require 'bunny'

def kill_tweetstream
  targets = (`ps -ef | grep -v grep | grep 'ruby tweetfeed' | grep -v #{$$} | awk '{print $2}'`).split
  targets.each do |t|
    puts "Found and killing tweetstream process number #{t}"
    Process.kill("KILL",t.to_i)
  end
  puts "Restarting tweetfeed process..."
# this prevents map from receiving messages, but manually restarting tweetfeed continues markering.
# Why? Something about the backticked tweetfeed, maybe?
# reference your code in streaming.rb and fork these instead of just backticking
#  sleep 1
#  `ruby tweetfeed.rb RT`
end

#kill_tweetstream
#exit

EM.run {
  EM::WebSocket.run(:host => "127.0.0.1", :port => 8567) do |ws|
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
    # this receives even though the rabbitmq subscription is looping...cool.
    ws.onmessage do |msg|
      puts "got message!"
      if msg == "ZUG"
        puts "Got kill orders."
        kill_tweetstream
        #this works...after this, restart tweetstream with new arguments
        #restart works, and socket gets tweets from new tweetstream, but map isn't
        # receiving tweets from socket after restart
      end
#      ch.default_exchange.publish("ZUG", :routing_key => ch.queue("command").name) 
# HOWEVER, using this causes websocket to close. Why?
    #try brute force method of kill and restart?
    end
  end
}

