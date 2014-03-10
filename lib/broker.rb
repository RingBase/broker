$LOAD_PATH.unshift('lib')

require 'strong_parameters'
require 'logger'
require 'json'
require 'yaml'
require 'amqp'
require 'eventmachine'
require 'thrift_client'
require 'thrift_client/event_machine'
require 'cassandra/1.2'
require 'goliath'
require 'goliath/websocket'
require 'broker/socket_server'
require 'broker/invoca_api'

# Prevent Goliath from auto-running
Goliath.run_app_on_exit = false

module Broker
  extend self

  attr_accessor :server, :logger, :cassandra,
                :channel, :exchange, :queue

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def run!
    self.logger   = Logger.new(STDOUT)

    get_cassandra_client!

    EventMachine.run do
      Broker.connect_amqp!
      Broker::InvocaAPI.listen

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

  def get_cassandra_client!
    host     = config['cassandra']['host']
    port     = config['cassandra']['port']
    keyspace = config['cassandra']['keyspace']
    username = config['cassandra']['username']
    password = config['cassandra']['password']
    EM.run do
      Fiber.new do
        @client = Cassandra.new(keyspace,
                                 "#{host}:#{port}",
                                 :transport_wrapper => nil,
                                 :transport => Thrift::EventMachineTransport)
        puts @client.get(:calls, "\x00\x00\x00\x01")
        EM.stop
      end.resume
    end
  end

end
