require 'eventmachine'
require 'bunny'

# Simulate Invoca's side of things
# i.e., listen for events over AMQP and write out as necessary

EventMachine.run do
  bunny = Bunny.new
  bunny.start

  ch = bunny.create_channel
  q  = ch.queue("hello_world", auto_delete: true)
  q.subscribe do |delivery_info, metadata, payload|
    puts "Got payload: #{payload}"
    # TODO: write to Cassandra, etc
  end
end
