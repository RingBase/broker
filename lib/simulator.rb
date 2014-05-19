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





  # TOOD: write back to RingBase over the update_exchange


  # Publisher
  # ---------------------------------------
  def send_call_start(call_opts=nil)
    json = JSON.dump({
      'type' => 'call_start',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_stop(call_opts=nil)
    json = JSON.dump({
      'type' => 'call_stop',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_accepted(call_opts=nil)
    json = JSON.dump({
      'type' => 'call_accepted',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end

  def send_call_transfer_completed(call_opts=nil)
    json = JSON.dump({
      'type' => 'call_transfer_completed',
      'call' => generate_call(call_opts)
    })
    send_event(json)
  end








  # Subscriber
  # ---------------------------------------

  # Listen for messages from the Broker and immediately respond with appropriate acks
  def listen
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    #vhost    = config['rabbitmq']['vhost']
    #connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}/#{vhost}")
    connection = AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")


    channel    = AMQP::Channel.new(connection)
    #queue      = channel.queue("broker_to_invoca", :auto_delete => true)

    control_channel_queue_name = config['control_channel_queue_name']
    queue = channel.queue(control_channel_queue_name, auto_delete: true)

    # TODO: listen on the control queue,

    puts "Established connection, listening for messages over AMQP..."

    queue.subscribe do |payload|
      json = JSON.parse(payload)
      process(json)
    end
  end

  def process(json)
    puts "PROCESS got json #{json}"


    type = json['type']
    send("sim_receive_#{type}", json)
  end



  # json - Hash of
  #   type
  #   call_uuid
  #   country_code
  #   national_number
  def sim_receive_bridge_to(json)

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
    puts "Sim receive call transfer request: parrot send_call_transfer_completed"
    sleep(0.3)
    send_call_transfer_completed(call)
  end









  private

  def config
    @config ||= YAML.load_file("config.yml")
  end

  # Publisher helper
  def create_connection
    username = config['rabbitmq']['username']
    password = config['rabbitmq']['password']
    host     = config['rabbitmq']['host']
    port     = config['rabbitmq']['port']
    AMQP.connect("amqp://#{username}:#{password}@#{host}:#{port}")
  end

  # Publisher helper
  def create_exchange
    connection = create_connection
    ch = AMQP::Channel.new(connection)
    #ex = ch.default_exchange
    update_exchange_name = config['update_exchange_name']
    ex = ch.fanout(update_exchange_name)

    [connection, ex]
  end



  # Publisher: create a new connection and exchange for each event
  # This is obviously not good, but it's only a temporary simulator
  def send_event(json)
    sleep(1)
    EM.schedule do
      connection,ex = create_exchange
      ex.publish(json)
      EM.add_timer(0.5) { connection.close }
    end
  end








  def generate_call(call_opts=nil)
    if call_opts.nil?
      {
        'id' => SecureRandom.uuid,
        'name' => Faker::Name.name,
        'email' => Faker::Internet.email,
        'city' => Faker::Address.city,
        'number' => generate_phone_number
      }
    else
      payload = {}

      %w(id name email city number).each do |attr|
        if field_val = call_opts.delete(attr)
          payload[attr] = field_val
        end
      end

      payload
    end
  end

  # Faker sucks at phone number formatting
  def generate_phone_number
    first  = rand_digits(3)
    second = rand_digits(3)
    third  = rand_digits(4)

    "#{first}-#{second}-#{third}"
  end

  # Helper for phone number generator
  def rand_digits(n)
    n.times.map { rand(0..9) }.join
  end

end
