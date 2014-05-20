module Broker
  class InvalidTypeError < StandardError; end

  class SocketServer < Goliath::WebSocket
    GOLIATH_HEADERS = 'goliath.request-headers'.freeze
    WS_KEY          = 'Sec-WebSocket-Key'.freeze

    # Memoized mapping of agent_id -> env
    def subscribers
      @subscribers ||= {}
    end

    #def channel
    #  @channel ||= EM::Channel.new
    #end


    # Get a unique key that identifies a request env
    # Return String
    def ws_key(env)
      env[GOLIATH_HEADERS][WS_KEY]
    end


    # Not much to do here; wait for client login message to
    # subscribe to event pipeline
    def on_open(env)
      Broker.log('[SocketServer] Opening connection')
    end


    # Raw WS message received - parse it and dispatch appropriate
    # client handler
    def on_message(env, raw_json)
      json = JSON.parse(raw_json)
      type = json['type'] or raise 'Missing required param: type'
      agent_id = json['agent_id']

      Broker.instrument('browser-broker', agent_id)
      EM.add_timer(0.25) { Broker.instrument('broker', agent_id) }

      EM.add_timer(0.5) do
        send("handle_client_#{type}", env, json)
      end
    end


    # Grab the WS key from the disconnecting env and delete it from our
    # subscriber list
    def on_close(env)
      Broker.log('[SocketServer] Closing connection')

      ws_key = ws_key(env)
      subscribers.delete_if do |agent_id, agent_env|
        ws_key(agent_env) == ws_key
      end
    end


    # Client dispatch methods


    # Client connected - subscribe them to the event pipeline
    #
    # data - Hash of
    #   :agent_id - Integer
    #
    def handle_client_login(env, data)
      agent_id = data['agent_id']
      subscribers[agent_id] = env
    end


    # Request from client after login to populate call table
    #
    # json - TODO
    #
    def handle_client_list_calls(env, json)
      org_pilot_number = json['org_pilot_number']
      agent_id         = json['agent_id']
      Broker.log("[SocketServer] list_calls, org_pilot number: #{org_pilot_number}, agent_id: #{agent_id}")

      calls = Broker::Cassandra2.get_calls_for_organization(org_pilot_number)

      Broker.instrument('browser-broker', agent_id)

      EM.add_timer(0.25) do
        Broker.instrument('browser', agent_id)
        client_broadcast('call_list', { calls: calls, agent_id: agent_id })
      end
    end


    # bridge_to encompasses request to accept and transfer calls
    #
    # data - Hash of
    #   :agent - Agent attributes hash
    #   :call - Call record attribute hash
    #
    def handle_client_bridge_to(env, data)
      Broker.log("[SocketServer] Received bridge_to, forwarding to Invoca")

      call_uuid       = data['call']['id']
      agent_id        = data['agent']['id']
      national_number = data['agent']['phone_number']

      bridge_msg = {
        "type" => "bridge_to",
        "call_uuid" => call_uuid,
        "country_code" => "1",
        "national_number" => national_number
      }

      EM.add_timer(0.25) do
        Broker.instrument('broker-invoca', agent_id)
        Broker.control_queue.publish(bridge_msg.to_json)

        EM.add_timer(0.5) { Broker.instrument('invoca', agent_id) }
      end
    end


    # call_stop sent by client when agent hangs up
    #   {
    #     "type" : "stop_call",
    #     "call_uuid": "asdf87-kjh2-kjh1skl"
    #   }
    def handle_client_call_stop(call_attrs)
      Broker.log('[SocketServer] Received call_stop, forwarding to Invoca')
      Broker.log(call_attrs)

      hangup_msg = {
        "type" => "hangup",
        "call_uuid" => call_attrs['id']
      }

      Broker.control_queue.publish(hangup_msg.to_json)
    end


    # Helper methods


    # Broadcast a message to all clients
    #
    # event - String event name, ex 'call_list'
    # data - Arbitrary Hash of JSON data
    #
    def client_broadcast(event, data)
      subscribers.each do |agent_id, agent_env|
        agent_env.stream_send(format_event(event, data))
      end
      nil
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
