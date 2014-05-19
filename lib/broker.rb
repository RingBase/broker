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
                :channel, :control_queue, :update_exchange, :update_queue,
                :cassandra

  self.logger = Logger.new(STDOUT)

  def config
    @config ||= YAML.load_file("config.yml")
  end


  def run!
    EventMachine.run do
      Broker.connect_amqp!
      Broker::InvocaAPI.listen

      connect_cassandra!
      # connect_messaging!

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
    #vhost    = config['rabbitmq']['vhost']

    #puts "connecting to amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}"
    #connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}")
    connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")
    self.channel  = AMQP::Channel.new(connection)

    # RingBase -> Invoca control queue
    control_channel_queue_name = config['control_channel_queue_name']
    self.control_queue = channel.queue(control_channel_queue_name, auto_delete: true)


    # Invoca -> RingBase update exchange
    update_exchange_name = config['update_exchange_name']
    self.update_exchange = channel.fanout(update_exchange_name)
    self.update_queue    = channel.queue('', exclusive: true)
    update_queue.bind(update_exchange)

    # self.queue    = self.channel.queue("invoca.ringswitch.call_updates", :auto_delete => true)
    # self.exchange = self.channel.default_exchange
  end


  def log(msg)
    puts "trying to log: #{msg}"
    logger.info(msg)
  end


  def connect_cassandra!
    host     = config['cassandra']['host']
    port     = config['cassandra']['port']
    keyspace = config['cassandra']['keyspace']
    #username = config['cassandra']['username']
    #password = config['cassandra']['password']
    Broker::Cassandra2.connect!(host: host, keyspace: keyspace, port: port)
  end

end
