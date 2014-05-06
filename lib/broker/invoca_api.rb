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
      call = json['call']
      send("handle_api_#{type}", call)
    end


    # json  - Hash of json data
    def publish(json)
      #Broker.exchange.publish(JSON.dump(json), routing_key: 'broker_to_invoca')

      Broker.log("[InvocaAPI] Publishing to control queue: #{json}")
      payload = JSON.dump(json) # Stringify JSON
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
      raise NotImplementedError
      # TODO: figure out state change and broadcast appropriate message
      # to client over socket server
    end







    # def handle_api_call_start(call)
    #   Broker.server.client_broadcast('call_start', call)
    # end

    # def handle_api_call_accepted(call)
    #   Broker.server.client_broadcast('call_accepted', call)
    # end

    # def handle_api_call_transfer_completed(call)
    #   Broker.server.client_broadcast('call_transfer_completed', call)
    # end

    # def handle_api_call_stop(call)
    #   Broker.server.client_broadcast('call_stop', call)
    # end







  end
end
