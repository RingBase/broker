# Handle incoming events from the Invoca API

module Broker
  module InvocaAPI
    extend self

    def listen
      Broker.log("[InvocaAPI] AMQP listener is listening on '#{Broker.config['update_exchange_name']}'")
      Broker.update_queue.subscribe do |payload|
        Broker.log("[InvocaApi] AMQP listener got payload: #{payload}")
        json = JSON.parse(payload)
        process(json)
      end
    end

    def process(json)
      type = json['type']
      send("handle_api_#{type}", json)
    end

    # json  - Hash of json data
    def publish(json)
      #Broker.exchange.publish(JSON.dump(json), routing_key: 'broker_to_invoca')

      Broker.log("[InvocaAPI] Publishing to control queue: #{json}")
      payload = JSON.dump(json) # Stringify JSON
      Broker.instrument('broker-invoca')
      Broker.control_queue.publish(payload)
    end

    # TODO:
    #
    # call_update
    #   Sent when call is updated, in any state.
    #   The first event for a call will be "parked". The final will be "stopped".
    #
    #   {
    #     "type": "call_update",
    #     "call_uuid": "asdf87-kjh2-kjh1skl",
    #     "call_state": "parked" | "bridging" | "bridged" | "stopped"
    #     "detail": "Caller hung up" | "Phone wasn't answered" | "Phone was busy" | ...
    #   }
    def handle_api_call_update(json)
      # raise NotImplementedError
      # TODO: figure out state change and broadcast appropriate message
      # to client over socket server
      Broker.log(json)

      call = Broker::Cassandra2.get_call_info(json["call_uuid"])
      if json.has_key?("call_state")
        call_state = json["call_state"]
      else
        call_state = json["state"]
      end

      call["id"] = json["call_uuid"]
      send("handle_api_call_#{call_state}", call)
    end

    def handle_api_call_parked(call)
      Broker.server.client_broadcast('call_start', call)
    end

    def handle_api_call_accepted(call)
      Broker.server.client_broadcast('call_accepted', call)
    end

    def handle_api_call_bridging(call)
      Broker.log("[InvocaAPI] got call bridging. #{call}")
      #Broker.server.client_broadcast('call_start', call)
    end

    def handle_api_call_bridged(call)
      Broker.log("[InvocaAPI] got call bridged. #{call}")
      Broker.server.client_broadcast('call_bridged', call)
    end

    def handle_api_call_stopped(call)
      Broker.server.client_broadcast('call_stop', call)
    end

  end
end
