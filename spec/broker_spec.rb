require File.dirname(__FILE__) + '/spec_helper'

describe Broker do

  context 'run!' do
    let(:bunny) { double("bunny") }
    let(:ch) { double("channel") }
    let(:ex) { double("exchange") }
    let(:q) { double("queue") }

    before(:each) do
      Bunny.stub(:new) { bunny }
    end

    around(:each) do |example|
      EM.run do
        example.run
        EM.stop
      end
    end

    it 'sets up a connection to the AMQP broker' do
      bunny.should_receive(:start)
      bunny.should_receive(:create_channel).and_return { ch }
      ch.should_receive(:default_exchange).and_return { ex }
      ch.should_receive(:queue).with("hello_world", { auto_delete: true }).and_return { q }

      Broker.connect_amqp!
    end
  end

end
