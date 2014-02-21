module Broker
  class InvalidTypeError < StandardError; end

  class SocketServer < Goliath::WebSocket
    Channels = {}


    # Invoca -> Broker
    # ------------------------------------------

    def initialize
      Broker.log("starting server")
      Broker.queue.subscribe do |payload|
        Broker.log(payload.inspect)
        json = JSON.parse(payload)
        process(json)
      end

      super
    end

    def process(json)
      type = json['type']
      call = json['call']
      send("handle_api_#{type}", call)
    end

    def handle_api_call_start(call)
      client_broadcast('call_start', call)
    end

    def handle_api_call_stop(call)
      client_broadcast('call_stop', call)
    end



    # Broker -> Invoca
    # ------------------------------------------

    def publish(msg)
      Broker.exchange.publish(msg, routing_key: 'broker_to_invoca')
    end



    # Browser -> Broker
    # ------------------------------------------

    def on_open(env)
      env.logger.info('Opening')
    end

    def on_message(env, json)
      data     = JSON.parse(json)
      type     = data.delete('type') or raise 'Missing required param: type'
      data['agent_id'] or raise 'Missing required param: agent_id'

      # TODO: params here depend on the event?
      send("handle_client_#{type}", data)
    end

    # TODO: How to properly remove channel state?
    def on_close(env)
      env.logger.info('Closing')
    end

    def handle_client_call_accept(call)
    end

    # TODO: understand subscribe()
    def handle_client_login(data)
      agent_id = data['agent_id']
      Channels[agent_id] = EM::Channel.new
      Channels[agent_id].subscribe { |msg| env.stream_send(msg) }
      Channels[agent_id] << format_event('join', { agent_id: agent_id })
    end



    # Broker -> Browser
    # ------------------------------------------

    def client_broadcast(event, data)
      Channels.each { |id, chan| chan << format_event(event, data) }
    end



    def method_missing(meth, *args, &block)
      if meth =~ /^handle_/
        raise InvalidTypeError, "Unknown event type: #{meth}"
      else
        super(meth, *args, &block)
      end
    end

    private

    def format_event(event, data)
      JSON.dump(type: event, data: data)
    end

    def stop
      EM.next_tick do
        EM.stop
        Broker.log("Stopped")
      end
    end

  end
end
