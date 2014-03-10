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
Setting up Cassandra locally with cqlsh 3.0 (plus test tables)
```
CREATE KEYSPACE ringbase WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor':1};

USE ringbase;

CREATE TABLE Calls (
id int PRIMARY KEY,
caller_name text,
caller_id text,
organization_id int,
notes text,
sale double
) WITH COMPACT STORAGE;

INSERT INTO Calls (id, caller_name, caller_id, organization_id, notes, sale)
 VALUES (1, 'Shervin Shaikh', '949-419-4942', 1, 'Yummy...ice cream', 8.5);
```
[Data Types for Cassandra in CQL](http://www.datastax.com/documentation/cql/3.0/cql/cql_reference/cql_data_types_c.html)



#### Create a new column family from broker
```
cf_def = CassandraThrift::CfDef.new(:keyspace => "RingBase", :name => "NewTableName")
client.add_column_family(cf_def)
```