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

  attr_accessor :server, :logger

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def publish(msg)
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
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    @bunny = Bunny.new("amqp://#{username}:#{password}@#{host}:#{port}")
    @bunny.start

    @ch = @bunny.create_channel
    @ex = @ch.default_exchange
    @q  = @ch.queue("invoca_to_broker", auto_delete: true)

    @q.subscribe do |delivery_info, metadata, payload|
      json = JSON.parse(payload, symbolize_names: true) # TODO: ?
      SocketServer.process(json)
    end
  end

  def setup_logger
    logger     = Log4r::Logger.new('goliath')
    log_format = Log4r::PatternFormatter.new(:pattern => "[#{Process.pid}:%l] %d :: %m")
    logger.add(Log4r::StdoutOutputter.new('console', formatter: log_format))
    logger.level = Log4r::DEBUG
    self.logger = logger
    logger
  end

  def setup_server
    api = Broker::SocketServer.new
    app = Goliath::Rack::Builder.build(Broker::SocketServer, api)

    address = config['server']['address']
    port    = config['server']['port']
    server  = Goliath::Server.new(address, port)

    server.logger  = setup_logger
    server.app     = app
    server.api     = api
    server.plugins = []
    server.options = {}
    server.api.setup if server.api.respond_to?(:setup)

    self.server = server
    server
  end

  def run_app!
    setup_server
    logger.info("Starting customized server on #{address}:#{port}. Watch out for stones.")
    self.server.start
  end

end
