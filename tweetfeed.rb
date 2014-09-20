#!/usr/bin/env ruby

require 'amqp'
require 'tweetstream'
require 'yaml'
require 'json'

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

keywords = 'burrito, sushi'
#keywords = 'zokfotpik'

AMQP.start(:host => 'localhost') do |connection, open_ok|
  AMQP::Channel.new(connection) do |channel, open_ok|
    twitter = channel.fanout("twitter")

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
        twitter.publish(tweetstring)
      end
    end
  end
end

