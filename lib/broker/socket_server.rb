module Broker

  class InvalidTypeError < StandardError; end

  # TODO: we'll probably want to split API/client handling
  # methods into modules or similar
  class SocketServer < Goliath::WebSocket
    Channels = {}

    def initialize
      Broker.queue.subscribe do |delivery_info, metadata, payload|
        json = JSON.parse(payload, symbolize_names: true) # TODO: ?
        process(json)
      end
      super
    end

    def process(json)
      type = json[:type]
      call = json[:call]
      send("handle_#{type}", call)
    end

    def handle_call_start(call)
    end

    def handle_call_stop(call)
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

    def method_missing(meth, *args, &block)
      if meth =~ /^handle_/
        raise InvalidTypeError, "Unknown action: #{meth}"
      else
        super(meth, *args, &block)
      end
    end

    private

    def peers(agent_id)
      Channels.reject { |id, _| id == agent_id }
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
      Channels[agent_id] = EM::Channel.new
      Channels[agent_id].subscribe { |msg| env.stream_send(msg) }

      Channels[agent_id] << format_message("logged in")
    end

    def handle_broadcast(agent_id, message)
      log_action("broadcast", agent_id)
      peers(agent_id).each { |id, chan| chan << format_message(message) }
      Broker.publish(message)
    end

    def handle_logout(agent_id)
      log_action("logout", agent_id)
      Channels.delete(agent_id)
    end

    def log_action(action, agent_id)
      env.logger.info("#{agent_id} => #{action}")
    end

  end
end
