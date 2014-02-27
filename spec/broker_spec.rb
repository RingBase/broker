require_relative 'spec_helper'

describe Broker do

  context '::connect_amqp!' do
    let(:connection) { double("connection") }

    before(:each) do
      Broker.stub(:config) do
        {
          'rabbitmq' => {
            'username' => 'guest',
            'password' => 'guest',
            'host' => 'localhost',
            'port' => 5672
          },
          'server' => {
            'address' => '0.0.0.0',
            'port' => 9000
          }
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
      AMQP.should_receive(:connect).with("amqp://guest:guest@localhost:5672")
      Broker.connect_amqp!
    end
  end

end
