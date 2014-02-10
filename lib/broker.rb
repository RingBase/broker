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

  attr_accessor :channel, :exchange, :queue

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def publish(msg)
    exchange.publish(msg, routing_key: "broker_to_invoca")
  end

  def run!
    EM.run do
      connect_amqp!
      run_app!
    end
  end

  # Connect Bunny to the AMQP broker and set up the inbound listener queue
  def connect_amqp!
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    bunny = Bunny.new("amqp://#{username}:#{password}@#{host}:#{port}")
    bunny.start

    self.channel  = bunny.create_channel
    self.exchange = channel.default_exchange
    self.queue    = channel.queue("invoca_to_broker", auto_delete: true)
  end

  def run_app!
    ARGV[1] = '-sv'
    Goliath::Application.run!
  end

end
