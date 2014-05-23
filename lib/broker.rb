$LOAD_PATH.unshift('lib')

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

  # Valid node/link titles for event visualizer
  NODES = [
    'browser',
    'browser-broker',
    'broker',
    'broker-cassandra',
    'cassandra',
    'broker-invoca',
    'invoca'
  ]

  extend self

  attr_accessor :server, :logger,
                :channel, :control_queue, :update_exchange, :update_queue,
                :cassandra

  self.logger = Logger.new(STDOUT)

  def config
    @config ||= YAML.load_file("config.yml")
  end


  def run!
    EventMachine.run do
      Broker.connect_amqp!
      Broker.connect_cassandra!
      Broker::InvocaAPI.listen

      self.server   = Broker::SocketServer.new
      runner        = Goliath::Runner.new(ARGV, server)
      runner.logger = logger
      runner.app    = Goliath::Rack::Builder.build(server.class, server)
      runner.run
    end
  end


  # Start an AMQP broker connection and set up the inbound listener queue
  def connect_amqp!
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    vhost    = config['rabbitmq']['vhost']

    puts "connecting to amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}"
    connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}")
    self.channel  = AMQP::Channel.new(connection)

    # RingBase -> Invoca control queue
    control_channel_queue_name = config['control_channel_queue_name']
    self.control_queue = channel.queue(control_channel_queue_name, auto_delete: true)


    # Invoca -> RingBase update exchange
    update_exchange_name = config['update_exchange_name']
    self.update_exchange = channel.fanout(update_exchange_name)
    self.update_queue    = channel.queue('', exclusive: true)
    update_queue.bind(update_exchange)
  end


  def connect_cassandra!
    host     = config['cassandra']['host']
    port     = config['cassandra']['port']
    keyspace = config['cassandra']['keyspace']
    #username = config['cassandra']['username']
    #password = config['cassandra']['password']
    Broker::CassandraConn.connect!(host: host, keyspace: keyspace, port: port)
  end


  # Broadcast an event to web clients to update the visualizer
  #
  # node_name - String node name, ex: 'browser'
  def instrument(node_name)
    Broker::NODES.include?(node_name) or raise "Invalid event node: #{node_name}"

    Broker.log("[Broker] INSTRUMENT: #{node_name}")
    self.server.client_broadcast('instrument', node: node_name)

    if block_given?
      EM.add_timer(0.25) { yield }
    end
  end


  def log(msg)
    logger.info(msg)
  end

end
