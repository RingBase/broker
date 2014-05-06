# require_relative 'spec_helper'
#
# describe 'Broker::SocketServer' do
#   before do
#     Broker.connect_amqp!
#     Broker.connect_cassandra!
#   end
#
#   let!(:server) { Broker::SocketServer.new }
#
#   let(:call_data) do
#     { 'id' => SecureRandom.uuid }
#   end
#
#
#   context 'Invoca -> Broker' do
#     context '#process' do
#       let(:event_data) do
#         { 'type' => nil, 'call' => call_data }
#       end
#
#       it 'dynamically dispatches handlers' do
#         server.should_receive(:handle_api_call_update).with(call_data)
#         event_data['type'] = 'call_update'
#         server.process(event_data)
#       end
#
#       it 'catches invalid handlers' do
#         event_data['type'] = 'unknown'
#         expect { server.process(event_data) }.to raise_error(Broker::InvalidTypeError)
#       end
#     end
#   end
#
#
#
#   context 'Broker -> Clients' do
#     context '#on_message' do
#       let(:agent_id) { rand(1..100) }
#
#       let(:event_data) do
#         { 'type' => nil, 'agent_id' => agent_id, 'call' => call_data }
#       end
#
#       let(:env) { {} }
#
#       it 'dynamically dispatches login client handlers' do
#           server.should_receive(:handle_client_login)
#                 .with({ 'agent_id' => agent_id })
#
#           json = JSON.dump({ 'type' => 'login', 'agent_id' => agent_id })
#           server.on_message(env, json)
#       end
#
#       [:call_bridge_to, :call_stop].each do |type|
#         it "dynamically dispatches #{type} client handlers" do
#           server.should_receive(:"handle_client_#{type}")
#                 .with({ 'agent_id' => agent_id, 'call' => call_data })
#
#           event_data['type'] = type
#           server.on_message(env, JSON.dump(event_data))
#         end
#       end
#     end
#   end
#
#
#
#   context '#handle_api_call_start' do
#     it 'sends an event to clients' do
#       server.should_receive(:client_broadcast).with('call_start', call_data)
#       server.handle_api_call_start(call_data)
#     end
#   end
#
# end
