require 'eventmachine'
require 'amqp'
require 'securerandom'
require 'json'
require 'faker'

# A simulator for the Invoca API, which both sends
# messages to the broker and receives them, all over AMQP

module Invoca
  extend self

  def send_call_start(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_start',
      'call' => generate_call(id)
    })
    send_event(json)
  end

  def send_call_stop(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_stop',
      'call' => generate_call(id)
    })
    send_event(json)
  end

  def send_call_accepted(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_accepted',
      'call' => generate_call(id)
    })
    send_event(json)
  end

  def send_call_transfer_complete(id = SecureRandom.uuid)
    json = JSON.dump({
      'type' => 'call_transfer_complete',
      'call' => generate_call(id)
    })
    send_event(json)
  end

  private

  def config
    @config ||= YAML.load_file("config.yml")
  end

  def create_connection
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")
  end

  def create_exchange
    connection = create_connection
    ch = AMQP::Channel.new(connection)
    ex = ch.default_exchange
    [connection, ex]
  end

  # Create a new connection and exchange for each event
  # This is obviously not good, but it's only a temporary simulator
  def send_event(json)
    EM.run do
      connection,ex = create_exchange
      ex.publish(json, :routing_key => 'invoca_to_broker')
      EM.add_timer(1) do
        p json
        connection.close { EM.stop }
      end
    end
  end

  def generate_call(id)
    {
      id: id,
      name: Faker::Name.name,
      email: Faker::Internet.email,
      city: Faker::Address.city,
      number: Faker::PhoneNumber.cell_phone
    }
  end

end
