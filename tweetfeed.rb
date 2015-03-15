#!/usr/bin/env ruby

require 'bunny'
require 'tweetstream'
require 'yaml'
require 'json'

cfgfile = 'auth.cfg'

cnf = YAML::load(File.open(cfgfile))

TweetStream.configure do |config|
  config.consumer_key       = cnf['ebola']['con_key']
  config.consumer_secret    = cnf['ebola']['con_sec']
  config.oauth_token        = cnf['ebola']['o_tok']
  config.oauth_token_secret = cnf['ebola']['o_tok_sec']
  config.auth_method        = cnf['ebola']['a_meth']
end

#keywords = 'zokfotpik'
keywords = ARGV[0]
#keywords = 'RT'


conn = Bunny.new
conn.start
ch = conn.create_channel
$x = ch.default_exchange
$tq = ch.queue("tweets")
$cq = ch.queue("command")

#$cq.subscribe(:block => true) do |delivery_info, properties, body|
#  puts "Got command #{body}."
#  cq.publish("Acknowledged.", :routing_key => cq.name)
#end
#$tq.subscribe(:block => true) do |delivery_info, properties, body|
#  puts "Got command #{body}."
#  tq.publish("Acknowledged.", :routing_key => tq.name)
#end

def monitor_stream(keywords)

  stream = TweetStream::Client.new
  stream.track(keywords) do |status|
    if status.geo?
      tweet = JSON.generate(status.attrs)
      contents = JSON.parse(tweet)
      pt1 = contents['coordinates']['coordinates'][1]
      pt2 = contents['coordinates']['coordinates'][0]
      user = contents['user']['screen_name']
      tweet_text = contents['text'].gsub("\t","").gsub("\n","")
      tweetstring = "#{pt1}\t#{pt2}\t#{user}\t#{tweet_text}\n"
      puts tweetstring
      $x.publish(tweetstring, :routing_key => $tq.name)
    end
  end
end

#testing out wrapping this in a websocket handler to listen to socket's commands...
monitor_stream(keywords)
