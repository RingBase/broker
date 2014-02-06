require_relative 'spec_helper'

describe 'Broker::SocketServer' do

  context '#process' do
    let(:call) do
      { call: { id: "abcd-1234" } }
    end

    let(:json) do
      { call: call }
    end

    [:call_start, :call_stop, :call_updated].each do |type|
      it "dynamically dispatches #{type} handlers" do
        Broker::SocketServer.should_receive(:"handle_#{type}").with(call)
        json[:type] = type
        Broker::SocketServer.process(json)
      end
    end

    it 'catches invalid handlers' do
      json[:type] = "unknown"
      expect do
        Broker::SocketServer.process(json)
      end.to raise_error(Broker::InvalidTypeError)
    end
  end

end
