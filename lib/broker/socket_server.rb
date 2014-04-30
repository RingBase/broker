module Broker
  class InvalidTypeError < StandardError; end

  class SocketServer < Goliath::WebSocket
    Channels = {}

    def on_open(env)
      env.logger.info('Opening')
    end

    def on_message(env, raw_json)
      json = JSON.parse(raw_json)
      type = json['type'] or raise 'Missing required param: type'
      #json['agent_id'] or raise 'Missing required param: agent_id'
      send("handle_client_#{type}", json)
    end

    # TODO: How to properly remove channel state?
    def on_close(env)
      env.logger.info('Closing')
    end







    # TODO: these are the only 2 events we send Invoca
    #
    # bridge_to
    #   - Encompasses request to call accept and transfer
    #   {
    #     "type" : "bridge_to",
    #     "call_uuid": "asdf87-kjh2-kjh1skl",
    #     "country_code": "1",
    #     "national_number": "7073227256
    #   }
    def handle_client_bridge_to(data)
      Broker.log("SS received bridge_to, forwarding to Invoca")
      Broker::InvocaAPI.publish(data)
    end


    # call_stop
    #   {
    #     "type" : "stop_call",
    #     "call_uuid": "asdf87-kjh2-kjh1skl"
    #   }
    def handle_client_call_stop(data)
      Broker.log("SS received call_stop, forwarding to Invoca")
      Broker::InvocaAPI.publish(data)
    end













    def handle_client_login(data)
      agent_id = data['agent_id']
      Channels[agent_id] = EM::Channel.new
      Channels[agent_id].subscribe { |msg| env.stream_send(msg) }
      #Channels[agent_id] << format_event('join', { agent_id: agent_id })
    end


    # Sent by client after login to populate call table data
    # json - TODO
    def handle_client_list_calls(json)
      org_id = json['org_id']
      agent_id = json['agent_id']
      Broker.log("Listing calls for organization: #{org_id}")
      calls = Broker::Cassandra.get_calls_for_organization(org_id)
      Channels[agent_id] << format_event('call_list', { calls: calls })
    end





    # def handle_client_call_accept(data)
    #   Broker::InvocaAPI.publish(data)
    # end

    # data: Hash with keys
    #   'agent_id' - The ID of the agent to transfer to
    #   'call_id' - The ID of the call to be transferred
    # def handle_client_call_transfer_request(data)
    #   Broker::InvocaAPI.publish(data.merge(type: 'call_transfer_request'))
    # end







    # TODO: hack for demo
    def handle_client_update_notes(data)
      agent_id = data.delete('agent_id')
      peers = Channels.reject { |id, _| id == agent_id }
      peers.each { |id, chan| chan << format_event('notes_updated', data) }
    end

    def handle_client_update_textarea(data)
      Channels.each { |id, chan| chan << format_event('textarea_updated', data) }
    end










    # Broadcast a message to all clients
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
