require_relative 'spec_helper'

describe 'Broker::SocketServer' do

  context '#process' do
    let(:server) { Broker::SocketServer.new }

    let(:call) do
      { call: { id: "abcd-1234" } }
    end

    let(:json) do
      { call: call }
    end

    let(:queue) { double("queue") }

    before { Broker.stub(:queue).and_return(queue) }

    [:call_start, :call_stop, :call_updated].each do |type|
      it "dynamically dispatches #{type} handlers" do
        queue.should_receive(:subscribe)
        server.should_receive(:"handle_#{type}").with(call)
        json[:type] = type
        server.process(json)
      end
    end

    it 'catches invalid handlers' do
      queue.should_receive(:subscribe)
      json[:type] = "unknown"
      expect { server.process(json) }.to raise_error(Broker::InvalidTypeError)
    end
  end

end
