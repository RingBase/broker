require_relative 'spec_helper'

describe Broker do

  context '::connect_amqp!' do
    let(:bunny) { double("bunny") }
    let(:ch) { double("channel") }
    let(:ex) { double("exchange") }
    let(:q) { double("queue") }

    before(:each) do
      Broker.stub(:config) do
        {
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
      ch.should_receive(:queue).with("invoca_to_broker", { auto_delete: true }).and_return { q }
      q.should_receive(:subscribe)

      Broker.connect_amqp!
    end
  end

end
