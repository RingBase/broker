require 'eventmachine'
require 'amqp'
require 'securerandom'
require 'json'
require 'faker'

# A simulator for the Invoca API, which both sends
# messages to the broker and receives them, all over AMQP
#
# A sim instance either sends or receives, not both
# Usage:
#   rake simulator:start  # Start the console to interactively send msgs
#   rake simulator:listen # Start the AMQP listener to receive msgs and send back acks


module Invoca
  extend self

  # Publisher
  # ---------------------------------------
  def send_call_start(call_opts={})
    json = JSON.dump({
      'type' => 'call_start',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_stop(call_opts={})
    json = JSON.dump({
      'type' => 'call_stop',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_accepted(call_opts={})
    json = JSON.dump({
      'type' => 'call_accepted',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_transfer_complete(call_opts={})
    json = JSON.dump({
      'type' => 'call_transfer_complete',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end


  # Subscriber
  # ---------------------------------------

  # Listen for events and immediately respond with appropriate acks
  def listen
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")
    channel    = AMQP::Channel.new(connection)
    queue      = channel.queue("broker_to_invoca", :auto_delete => true)

    puts "Established connection, listening for messages over AMQP..."
    queue.subscribe do |payload|
      puts("API LISTENER GOT PAYLOAD: #{payload}")
      json = JSON.parse(payload)
      process(json)
    end
  end

  def process(json)
    type = json['type']
    call = json['call']
    send("sim_receive_#{type}", call)
  end

  # Receive a call accept message and immediately send
  # call_accepted ack
  def sim_receive_call_accept(call)
    puts "Sim receive call accept: parrot send_call_accepted"
    sleep(0.3)
    send_call_accepted(call)
  end

  # Receive a call transfer request and immediately send
  # call_transfer_complete ack
  def sim_receive_call_transfer_request(call)
    puts "Sim receive call transfer request: parrot send_call_transfer_complete"
    sleep(0.3)
    send_call_transfer_complete(call)
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

  # TODO: wat
  def generate_call(call_opts={})
    if call_opts.nil?
      p 'HOW DO DEFAULT ARGS'
    end
    id     = call_opts.delete('id')     || SecureRandom.uuid
    name   = call_opts.delete('name')   || Faker::Name.name
    email  = call_opts.delete('email')  || Faker::Internet.email
    city   = call_opts.delete('city')   || Faker::Address.city
    number = call_opts.delete('number') || Faker::PhoneNumber.cell_phone

    {
      'id' => id,
      'name' => name,
      'email' => email,
      'city' => city,
      'number' => number
    }
  end

end
