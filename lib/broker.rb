require 'json'
require 'yaml'
require 'bunny'
require 'goliath'
require 'goliath/websocket'
require_relative 'broker/socket_server'

# Prevent Goliath from auto-running
Goliath.run_app_on_exit = false


class Broker

  Channels = {}

  # TODO: probably will want to load config from YAML or similar
  QUEUE_NAME = "hello_world"

  class << self
    attr_accessor :bunny, :ch, :ex, :q

    def config
      @config ||= YAML.load_file("config.yml")
    end

    def publish(msg)
      raise "Not connected!" unless self.bunny.connected?
      self.ex.publish(msg, routing_key: config["queue_name"])
    end

    # TODO: Goliath nomally starts the reactor itself.
    # Is there any reason we can't wrap it in our own run loop?
    def run!
      EM.run do
        connect_amqp!
        run_app!
      end
    end

    # TODO: handle connection/auth errors
    def connect_amqp!
      self.bunny = Bunny.new
      self.bunny.start

      self.ch = bunny.create_channel
      self.ex = ch.default_exchange
      self.q  = ch.queue(config["queue_name"], auto_delete: true)
    end

    def run_app!
      # TODO: massive hack to enable stdout logging, since it doesn't appear we can
      # change settings programatically. Eventually we'll want a more robust
      # logging solution anyways
      ARGV[1] = "-sv"
      Goliath::Application.run!
    end
  end

end
