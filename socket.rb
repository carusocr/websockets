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
5. Cleaner handling of heatmaps, loading point from file.


***TROUBLESHOOTING/BUG LIST

1. map.html is closing websocket after sending keyword list.
2. map.html doesn't clear contents of loaded files after "Reset Map".

***
=end

require 'em-websocket'
require 'uuid'
require 'bunny'

def refresh_tweetstream(searchterm)
  targets = (`ps -ef | grep -v grep | grep 'ruby tweetfeed' | grep -v #{$$} | awk '{print $2}'`).split
  targets.each do |t|
    puts "Found and killing tweetstream process number #{t}"
    Process.kill("KILL",t.to_i)
  end
  puts "Starting tweetfeed process..."
  Process.fork {start_tweetstream_process(searchterm)}
end

def start_tweetstream_process(searchterm)
  `ruby tweetfeed.rb #{searchterm}`
end

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
      if msg =~ /^START/
        puts "got #{msg}\n"
        # need to add some formatting to this...
        msg = msg.gsub(' ',',')
        msg = msg[6,msg.length] # remove command word
        puts "tracking keywords #{msg}..."
        refresh_tweetstream(msg)
      else
        puts "Got unintelligible command, please resend."
      end
    end
  end
}

