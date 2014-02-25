module Broker
  
  module InvocaAPI
    extend self
    
    def start
      Broker.queue.subscribe do |payload|
        Broker.log("GOT PAYLOAD: #{payload}")
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

    def handle_api_call_stop(call)
      Broker.server.client_broadcast('call_stop', call)
    end

    def publish(msg)
      Broker.exchange.publish(msg, routing_key: 'broker_to_invoca')
    end

  end
end
