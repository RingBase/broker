require 'strong_parameters'
require 'json'
require 'yaml'
require 'bunny'
require 'goliath'
require 'goliath/websocket'
require_relative 'broker/socket_server'

# Prevent Goliath from auto-running
Goliath.run_app_on_exit = false

module Broker
  extend self

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def publish(msg)
    raise "Not connected!" unless @bunny.connected?
    @ex.publish(msg, routing_key: "broker_to_invoca")
  end

  def run!
    EM.run do
      connect_amqp!
      run_app!
    end
  end

  # Connect Bunny to the AMQP broker and set up the inbound listener queue
  def connect_amqp!
    username = config['username']
    password = config['password']
    host     = config['host']
    port     = config['port']
    @bunny = Bunny.new("amqp://#{username}:#{password}@#{host}:#{port}")
    @bunny.start

    @ch = @bunny.create_channel
    @ex = @ch.default_exchange
    @q  = @ch.queue("invoca_to_broker", auto_delete: true)

    @q.subscribe do |delivery_info, metadata, payload|
      puts "BROKER GOT: #{payload}"
    end
  end

  def run_app!
    # TODO: massive hack to enable stdout logging, since it doesn't appear we can
    # change settings programatically. Eventually we'll want a more robust
    # logging solution anyways
    ARGV[1] = "-sv"
    Goliath::Application.run!
  end

end
