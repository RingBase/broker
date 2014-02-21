require 'eventmachine'
require 'amqp'
require 'securerandom'
require 'json'

# A simulator for the Invoca API, which both sends
# messages to the broker and receives them, all over AMQP

module Invoca
  extend self

  def send_call_start(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_start',
      'call' => { id: id }
    })
    ex.publish(json, :routing_key => 'invoca_to_broker')
    json
  end

  def send_call_stop(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_stop',
      'call' => { id: id }
    })
    ex.publish(json, routing_key: 'invoca_to_broker')
    json
  end

  def send_call_accepted(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_accepted',
      'call' => { id: id }
    })
    ex.publish(json, routing_key: 'invoca_to_broker')
    json
  end

  def send_call_transfer_complete(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_transfer_complete',
      'call' => { id: id }
    })
    ex.publish(json, routing_key: 'invoca_to_broker')
    json
  end

  # TODO:
  # call_accept (receive)
  # call_accepted (send)
  #
  # call_transfer_request (receive)
  # call_transfer_complete (send)

  private

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def connection
    @connection ||= begin
      username = config['rabbitmq']['username']
      password = config['rabbitmq']['password']
      host     = config['rabbitmq']['host']
      port     = config['rabbitmq']['port']
      AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")
    end
  end

  def ex
    @ex ||= begin
      ch = AMQP::Channel.new(connection)
      ex = ch.default_exchange
      ex
    end
  end


end
