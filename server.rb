require 'json'
require 'goliath'
require 'goliath/websocket'
require 'bunny'


class Broker

  Channels = {}

  class << self
    attr_accessor :bunny, :ch, :ex, :q
  end


  def self.amqp_send(msg)
    raise "not connected" unless self.bunny.connected?
    self.ex.publish(msg, routing_key: "hello_world")
  end


  EM.next_tick do
    self.bunny = Bunny.new
    self.bunny.start

    self.ch = bunny.create_channel
    self.ex = ch.default_exchange
    self.q  = ch.queue("hello_world", auto_delete: true)
    puts "==> set up Broker.q"
  end





  class SocketServer < Goliath::WebSocket

    # TODO - this belongs on Invoca's side
    EM.next_tick do
      puts "==> subscribing Broker.q"
      Broker.q.subscribe do |delivery_info, metadata, payload|
        puts "GOT PAYLOAD: #{payload}"
      end
    end


    def on_open(env)
      env.logger.info("Opening")
    end

    def on_message(env, json)
      msg      = JSON.parse(json)
      agent_id = msg['agent_id'] or raise "Missing required param: agent_id"
      action   = msg['action'] or raise "Missing required param: action_id"

      action == 'broadcast' ? handle_broadcast(agent_id, msg['data']) :
                              send("handle_#{action}", agent_id)
      rescue Exception => e
        puts "ERROR => #{e.message}"
    end

    # TODO: this relies on logout message being sent properly before close?
    # How to actually remove channel state?
    def on_close(env)
      env.logger.info("Closing")
    end

    # def response(env)
    #   if env['REQUEST_PATH'] == '/ws'
    #     super(env)
    #   else
    #     raise "Unknown path"
    #   end
    # end

    private

    def peers(agent_id)
      Broker::Channels.reject { |id, _| id == agent_id }
    end

    def format_message(message)
      JSON.dump(type: 'message', message: message)
    end

    def format_error(message)
      JSON.dump(type: 'error', message: message)
    end

    # TODO: When we push a message to the channel, push it to the client ??
    def handle_login(agent_id)
      log_action("login", agent_id)
      Broker::Channels[agent_id] = EM::Channel.new
      Broker::Channels[agent_id].subscribe { |msg| env.stream_send(msg) }

      Broker::Channels[agent_id] << format_message("logged in")
    end

    def handle_broadcast(agent_id, message)
      log_action("broadcast", agent_id)
      peers(agent_id).each { |id, chan| chan << format_message(message) }
      Broker.amqp_send(message)
    end

    def handle_logout(agent_id)
      log_action("logout", agent_id)
      Broker::Channels.delete(agent_id)
    end

    def log_action(action, agent_id)
      env.logger.info("#{agent_id} => #{action}")
    end

    def method_missing(meth, *args, &block)
      if meth =~ /^handle_/
        raise ArgumentError, "Unknown action: #{meth}"
      else
        super(meth, *args, &block)
      end
    end

  end
end

