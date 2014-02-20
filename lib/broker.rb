require 'strong_parameters'
require 'logger'
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

  attr_accessor :server, :logger,
                :channel, :exchange, :queue

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def run!
    connect_amqp!

    self.server   = Broker::SocketServer.new
    self.logger   = Logger.new(STDOUT)
    runner        = Goliath::Runner.new(ARGV, server)
    runner.logger = logger
    runner.app    = Goliath::Rack::Builder.build(server.class, server)
    runner.run
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

  def log(msg)
    logger.info(msg)
  end

end
