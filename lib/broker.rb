$LOAD_PATH.unshift('lib')

#require 'strong_parameters'
require 'logger'
require 'json'
require 'yaml'
require 'amqp'
require 'eventmachine'
require 'cql'
require 'goliath'
require 'goliath/websocket'
require 'broker/socket_server'
require 'broker/invoca_api'
require 'broker/cassandra'

# Prevent Goliath from auto-running
Goliath.run_app_on_exit = false

module Broker
  extend self

  attr_accessor :server, :logger,
                :channel, :exchange, :queue,
                :cassandra

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def run!
    self.logger   = Logger.new(STDOUT)

    EventMachine.run do
      Broker.connect_amqp!
      Broker::InvocaAPI.listen

      connect_cassandra!

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

  def connect_cassandra!
    host     = config['cassandra']['host']
    #port     = config['cassandra']['port']
    keyspace = config['cassandra']['keyspace']
    #username = config['cassandra']['username']
    #password = config['cassandra']['password']
    Broker::Cassandra.connect!(host: host, keyspace: keyspace)
  end

end
