## Broker

This is the RingBase WebSocket/AMQP broker which sits between browser clients and Invoca's API.
It receives incoming messages over AMQP and relays them to clients over WebSockets, as well
as handling data flow in the opposite direction.

### Usage

Make sure you have all the dependencies installed by running `bundle install`. Then, you can start
the server with a [Rake](http://rake.rubyforge.org/) task by calling each of the following in a separate terminal session:

```
$ rabbitmq-server
$ rake broker
```

### Simulator - Publishing
You can start the interactive Invoca publisher simulator (say that ten times fast) by running

```
$ rake simulator:start
```

This starts an IRB session where you can enter commands to mimic sending events from Invoca.
The following methods are supported, which send events to the Broker over AMQP:

`Invoca.send_call_start` - Send a call_start event

`Invoca.send_call_stop` - Send a call_stop event

`Invoca.send_call_accepted` - Send a call_accepted event

`Invoca.send_call_transfer_complete` - Send a call_transfer_complete event

All methods take an optional hash of call attributes, which will be filled with random data if none is provided.


### Simulator - Subscribing
You can start the simulator listener (which receives events and sends back ACKs) by running:

```
$ rake simulator:listen
```




### Status
[![Build Status](https://travis-ci.org/RingBase/broker.png?branch=master)](https://travis-ci.org/RingBase/broker)

### Cassandra
Setting up Cassandra locally with cqlsh
```
CREATE KEYSPACE ringbase WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor':3};
USE ringbase;

```
