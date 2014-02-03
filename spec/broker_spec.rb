require File.dirname(__FILE__) + '/spec_helper'

describe Broker do

  context 'run!' do
    let(:bunny) { double("bunny") }
    let(:ch) { double("channel") }
    let(:ex) { double("exchange") }
    let(:q) { double("queue") }

    before(:each) do
      Broker.stub(:config) do
        {
          "queue_name" => "test_queue",
          "username" => "guest",
          "password" => "guest",
          "host" => "localhost",
          "port" => 5672
        }
      end
    end

    around(:each) do |example|
      EM.run do
        example.run
        EM.stop
      end
    end

    it 'sets up a connection to the AMQP broker' do
      Bunny.should_receive(:new).with("amqp://guest:guest@localhost:5672").and_return(bunny)
      bunny.should_receive(:start)
      bunny.should_receive(:create_channel).and_return { ch }
      ch.should_receive(:default_exchange).and_return { ex }
      ch.should_receive(:queue).with("test_queue", { auto_delete: true }).and_return { q }

      Broker.connect_amqp!
    end
  end

end
