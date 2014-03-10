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
CREATE KEYSPACE ringbase WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor':1};
USE ringbase;
CREATE TABLE calls (
id uuid PRIMARY KEY,
caller_name text,
caller_id text,
organization_id uuid,
notes text,
sale double
);
INSERT INTO calls (id, caller_name, caller_id, organization_id, notes, sale)
 VALUES (62c36092-82a1-3a00-93d1-46196ee77204, 'shervin', '949-419-4942',
 7db1a490-5878-11e2-bcfd-0800200c9a66,
 'Ojo Rojo', 8.5);
```
