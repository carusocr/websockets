#!/usr/bin/env ruby

require 'amqp'
require 'tweetstream'
require 'yaml'

cfgfile = 'auth.cfg'

cnf = YAML::load(File.open(cfgfile))

TweetStream.configure do |config|
  config.consumer_key       = cnf['ebola']['con_key']
  config.consumer_secret    = cnf['ebola']['con_sec']
  config.oauth_token        = cnf['ebola']['o_tok']
  config.oauth_token_secret = cnf['ebola']['o_tok_sec']
  config.auth_method        = cnf['ebola']['a_meth']
end

keywords = 'burrito, sushi'

AMQP.start(:host => 'localhost') do |connection, open_ok|
  AMQP::Channel.new(connection) do |channel, open_ok|
    twitter = channel.fanout("twitter")

    stream = TweetStream::Client.new
    stream.track(keywords) do |status|
      twitter.publish(status)
      puts status.text
    end
  end
end

