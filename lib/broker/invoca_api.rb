# Handle incoming events from the Invoca API

module Broker
  module InvocaAPI
    extend self

    def listen
      Broker.queue.subscribe do |payload|
        Broker.log("InvocaApi AMQP listener got payload: #{payload}")
        json = JSON.parse(payload)
        process(json)
      end
    end

    def process(json)
      type = json['type']
      call = json['call']
      send("handle_api_#{type}", call)
    end

    def handle_api_call_start(call)
      Broker.server.client_broadcast('call_start', call)
    end

    def handle_api_call_accepted(call)
      Broker.server.client_broadcast('call_accepted', call)
    end

    def handle_api_call_transfer_completed(call)
      Broker.server.client_broadcast('call_transfer_completed', call)
    end

    def handle_api_call_stop(call)
      Broker.server.client_broadcast('call_stop', call)
    end

    def publish(json)
      Broker.exchange.publish(JSON.dump(json), routing_key: 'broker_to_invoca')
    end

  end
end
