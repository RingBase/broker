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


CREATE COLUMNFAMILY Calls (
call_uuid uuid PRIMARY KEY,
state text,
calling_country_code text,
calling_national_number text,
called_country_code text,
called_national_number text,
caller_name text,
notes text,
sale_currency text,
sale_amount text
) WITH COMPACT STORAGE;

INSERT INTO Calls (call_uuid, state, calling_country_code, calling_national_number, called_country_code, called_national_number, caller_name, notes, sale_currency, sale_amount)
 VALUES (f0b228d0-ca7c-11e3-9c1a-0800200c9a66, 'parked', '1', '8056213030', '1', '8003334444', 'Joe Smith', 'one\ntwo', 'USD', '25.32');
```
[Data Types for Cassandra in CQL](http://www.datastax.com/documentation/cql/3.0/cql/cql_reference/cql_data_types_c.html)

### Indexing
Setting up Cassandra indices to perform queries
```
CREATE INDEX ON Calls (name);
CREATE INDEX ON Calls (number);
CREATE INDEX ON Calls (city);
CREATE INDEX ON Calls (organization_id);
CREATE INDEX ON Calls (sale);
CREATE INDEX ON Calls (status);







