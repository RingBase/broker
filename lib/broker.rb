$LOAD_PATH.unshift('lib')

require 'strong_parameters'
require 'logger'
require 'json'
require 'yaml'
require 'amqp'
require 'goliath'
require 'goliath/websocket'
require 'broker/socket_server'

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
    self.logger   = Logger.new(STDOUT)
    
    EventMachine.run do
      connect_amqp!
      self.server   = Broker::SocketServer.new
      runner        = Goliath::Runner.new(ARGV, server)
      runner.logger = logger
      runner.app    = Goliath::Rack::Builder.build(server.class, server)
      runner.run
    end
  end

  # start an AMQP broker connection and set up the inbound listener queue
  def connect_amqp!
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    puts "connecting to amqp://#{username}:#{password}@#{host}:#{port}"

    connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")

    self.channel  = AMQP::Channel.new(connection)
    self.queue    = self.channel.queue("invoca_to_broker", :auto_delete => true)
    self.exchange = self.channel.default_exchange
  end

  def log(msg)
    logger.info(msg)
  end

end
