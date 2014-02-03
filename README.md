## Broker

This is the RingBase WebSocket/AMQP broker which sits between browser clients and Invoca's API.
It receives incoming messages over AMQP and relays thenm to clients over WebSockets, as well
as handling data flow in the opposite direction.

## Usage

Make sure you have all the dependencies installed by running `bundle install`. Then, you can start
the server with a [Rake](http://rake.rubyforge.org/) task by calling

```
rake broker:start
```

### Status
[![Build Status](https://travis-ci.org/RingBase/broker.png?branch=master)](https://travis-ci.org/RingBase/broker)
