require 'eventmachine'
require 'securerandom'
require 'json'

#EventMachine.run do
  module Invoca
    extend self

    def config
      @config ||= YAML.load_file("config.yml")
    end

    def bunny
      @bunny ||= begin
        username = config['rabbitmq']['username']
        password = config['rabbitmq']['password']
        host     = config['rabbitmq']['host']
        port     = config['rabbitmq']['port']
        bunny = Bunny.new("amqp://#{username}:#{password}@#{host}:#{port}")
        bunny.start
        bunny
      end
    end

    def ex
      @ex ||= begin
        ch = bunny.create_channel
        ch.default_exchange
      end
    end


    def call_start
      json = JSON.dump({
        type: "call_start",
        call: { id: SecureRandom.uuid }
      })
      ex.publish(json, routing_key: "invoca_to_broker")
      json
    end

    def call_stop
      json = JSON.dump({
        type: "call_stop",
        call: { id: SecureRandom.uuid }
      })
      ex.publish(json, routing_key: "invoca_to_broker")
      json
    end

  end
#end
