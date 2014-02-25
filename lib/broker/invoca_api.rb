module Broker
  
  module InOutBoundInvoca
    
    # Invoca -> Broker
    # ------------------------------------------

    def self.start
      Broker.queue.subscribe do |payload|
        Broker.log("GOT PAYLOAD: #{payload}")
        json = JSON.parse(payload)
        Broker::InOutBoundInvoca.process(json)
      end
    end

    def self.process(json)
      type = json['type']
      call = json['call']
      send("handle_api_#{type}", call)
    end

    def self.handle_api_call_start(call)
      Broker.server.client_broadcast('call_start', call)
    end

    def self.handle_api_call_stop(call)
      Broker.server.client_broadcast('call_stop', call)
    end

    # Broker -> Invoca
    # ------------------------------------------

    def self.publish(msg)
      Broker.exchange.publish(msg, routing_key: 'broker_to_invoca')
    end

  end
end
