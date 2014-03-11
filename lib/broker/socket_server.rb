module Broker
  class InvalidTypeError < StandardError; end

  class SocketServer < Goliath::WebSocket
    Channels = {}

    def on_open(env)
      env.logger.info('Opening')
    end

    def on_message(env, raw_json)
      json = JSON.parse(raw_json)
      type = json.delete('type') or raise 'Missing required param: type'
      json['agent_id'] or raise 'Missing required param: agent_id'
      send("handle_client_#{type}", json)
    end

    # TODO: How to properly remove channel state?
    def on_close(env)
      env.logger.info('Closing')
    end

    def handle_client_list_calls(json)
      agent_id = json['agent_id']
      Broker.log("Listing calls for agent: #{agent_id}")
      calls = [
        {
          id: '1',
          number: '111-111-1111',
          name: 'Name One',
          city: 'City One',
        },

        {
          id: '2',
          number: '222-222-2222',
          name: 'Name Two',
          city: 'City Two',
        }
      ]
      Channels[agent_id] << format_event('call_list', { calls: calls })
    end

    def handle_client_call_accept(data)
      Broker::InvocaAPI.publish(data.merge(type: 'call_accept'))
    end


    # data: Hash with keys
    #   'agent_id' - The ID of the agent to transfer to
    #   'call_id' - The ID of the call to be transferred
    def handle_client_call_transfer_request(data)
      Broker::InvocaAPI.publish(data.merge(type: 'call_transfer_request'))
    end

    # TODO: understand subscribe()
    def handle_client_login(data)
      agent_id = data['agent_id']
      Channels[agent_id] = EM::Channel.new
      Channels[agent_id].subscribe { |msg| env.stream_send(msg) }
      #Channels[agent_id] << format_event('join', { agent_id: agent_id })
    end

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
