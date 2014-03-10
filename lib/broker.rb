$LOAD_PATH.unshift('lib')

require 'strong_parameters'
require 'logger'
require 'json'
require 'yaml'
require 'amqp'
require 'eventmachine'
require 'thrift_client'
require 'thrift_client/event_machine'
require 'cql'
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

    # get_cassandra_client!
    cassandra
    # puts @client.get(:Users, '62c36092-82a1-3a00-93d1-46196ee77204')
    puts "I'm moving on"

    EventMachine.run do
      Broker.connect_amqp!
      Broker::InvocaAPI.listen

      self.server   = Broker::SocketServer.new
      runner        = Goliath::Runner.new(ARGV, server)
      runner.logger = logger
      runner.app    = Goliath::Rack::Builder.build(server.class, server)
      runner.run
      # client = get_cassandra_client!
      # puts 'connected'
      # puts client
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

  # Connect the Cassandra client
  def cassandra
    client = Cql::Client.connect(hosts: 127.0.0.1)
    client.use('ringbase')
    # rows = client.execute('SELECT keyspace_name, columnfamily_name FROM schema_columnfamilies')
    # rows.each do |row|
    #   puts "The keyspace #{row['keyspace_name']} has a table called #{row['columnfamily_name']}"
    # end
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
        puts @client.inspect
        puts @client.keyspaces
        # puts @client.add_column_family('testing')
        @client.get(:calls, '62c36092-82a1-3a00-93d1-46196ee77204')
        # puts @client.get(:calls, '62c36092-82a1-3a00-93d1-46196ee77204')
        # puts call
        # @client.clear_keyspace!
        EM.stop
      end.resume
    end

#     EM.run do 
#           Fiber.new do 
#               @cass = Cassandra.new('Keyspace1', '10.202.27.25:9160, 
# 10.244.154.48:9160, 10.244.154.240:9160', :transport => 
# Thrift::EventMachineTransport, :transport_wrapper => nil ) 
#               user = @cass.get(:Standard2, params[:id]) 
#               puts user 
#           end.resume 
#       end 

    # fiber = Fiber.new do
    #   self.cassandra = Cassandra.new(keyspace,
    #                                "#{host}:#{port}",
    #                                :transport_wrapper => nil,
    #                                :transport => Thrift::EventMachineTransport)
    #   self.cassandra.login!(username, password)
    #   puts self.cassandra.inspect
    # end

    # puts fiber.resume
  end

end
