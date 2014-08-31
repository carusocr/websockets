#!/usr/bin/env ruby

require 'faye/websocket'

module ChatDemo
  class ChatBackend
    KEEPALIVE_TIME = 15
    
    def initialize(app)
      @app = app
      @clients = []
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })

        ws.on :open do |event|
          puts [:open, ws.object_id]
          @clients << ws
        end

        ws.on :message do |event|
          puts [:message, event.data]
          @clients.each {|client| client.send(event.data) }
        end
    
        ws.on :close do |event|
          puts [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end
      
        # Return async Rack response

        ws.rack_response
      else

        @app.call(env)
      end
    end

  end
end
