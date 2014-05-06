module Broker
  class InvalidTypeError < StandardError; end

  class SocketServer < Goliath::WebSocket
    Channels = {}

    def on_open(env)
      #env.logger.info('[SocketServer] Opening connection')
      Broker.log('[SocketServer] Opening connection')
    end

    def on_message(env, raw_json)
      json = JSON.parse(raw_json)
      type = json['type'] or raise 'Missing required param: type'
      #json['agent_id'] or raise 'Missing required param: agent_id'
      send("handle_client_#{type}", json)
    end

    # TODO: How to properly remove channel state?
    def on_close(env)
      #env.logger.info('[SocketServer] Closing connection')
      Broker.log('[SocketServer] Closing connection')
    end







    # bridge_to encompasses request to call accept and transfer
    #
    # data - Hash of
    #   :agent - Agent attributes hash
    #   :call - Call record hash
    #
    def handle_client_bridge_to(data)
      Broker.log("[SocketServer] Received bridge_to, forwarding to Invoca")

      call_uuid       = data['call']['call_uuid']
      national_number = data['agent']['phone_number']

      Broker::InvocaAPI.publish({
       type: 'bridge_to' ,
       call_uuid: call_uuid,
       country_code: '1',
       national_number: national_number
      })
    end


    # call_stop sent by client when agent hangs up
    #   {
    #     "type" : "stop_call",
    #     "call_uuid": "asdf87-kjh2-kjh1skl"
    #   }
    def handle_client_call_stop(call_attrs)
      Broker.log('[SocketServer] Received call_stop, forwarding to Invoca')
      Broker::InvocaAPI.publish(call_attrs)
    end













    def handle_client_login(data)
      agent_id = data['agent_id']
      Channels[agent_id] = EM::Channel.new
      Channels[agent_id].subscribe { |msg| env.stream_send(msg) }
      #Channels[agent_id] << format_event('join', { agent_id: agent_id })
    end


    # Request from client after login to populate call table
    #
    # json - TODO
    #
    def handle_client_list_calls(json)
      org_pilot_number = json['org_pilot_number']
      agent_id         = json['agent_id']

      Broker.log("[SocketServer] list_calls, org_pilot number: #{org_pilot_number}")
      calls = Broker::Cassandra.get_calls_for_organization(org_pilot_number)
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
        Broker.log("[SocketServer] Stopped")
      end
    end

  end
end
