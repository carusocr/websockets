#!/usr/bin/env ruby

require 'amqp'
require 'tweetstream'
require 'yaml'

cfgfile = 'auth.cfg'

username=ARGV.shift
pwd=ARGV.shift

cnf = YAML::load(File.open(cfgfile))

TweetStream.configure do |config|
  config.consumer_key       = cnf['ebola']['con_key']
  config.consumer_secret    = cnf['ebola']['con_sec']
  config.oauth_token        = cnf['ebola']['o_tok']
  config.oauth_token_secret = cnf['ebola']['o_tok_sec']
  config.auth_method        = cnf['ebola']['a_meth']
end

#keywords = 'burrito, sushi'
keywords = 'zokfotpik'

AMQP.start(:host => 'localhost') do |connection, open_ok|
  AMQP::Channel.new(connection) do |channel, open_ok|
    twitter = channel.fanout("twitter")

    stream = TweetStream::Client.new
    stream.track(keywords) do |status|
      #twitter.publish(status.text)
      twitter.publish(status.id)
      puts status.text
#got socket working! But ran into this:
#/Users/carusocr/.rvm/gems/ruby-2.1.1/gems/em-websocket-0.5.1/lib/em-websocket/connection.rb:157:in `send_text': Data sent to WebSocket must be valid UTF-8 but was ASCII-8BIT (valid: true) (EventMachine::WebSocket::WebSocketError)
#so, need to make sure it's always converted to UTF-8 before sending
    end
  end
end

