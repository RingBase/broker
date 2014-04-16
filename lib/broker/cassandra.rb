module Broker
  module Cassandra
    extend self


    def connect!(options={})
      host     = options.delete(:host)
      keyspace = options.delete(:keyspace)
      Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
    end


    # TODO: this will need to take parameters, ex: organization_id
    def get_calls
      calls = []
      rows = Broker.cassandra.execute("Select * from calls")
      rows.each do |row|
        calls << row
      end
      calls
    end


    # TODO: remove this
    def insert_call(options={})
      id          = options.delete(:id)
      caller_id   = quote(options.delete(:caller_id))
      caller_name = quote(options.delete(:caller_name))
      notes       = quote(options.delete(:notes))
      organization_id = options.delete(:organization_id)
      sale        = options.delete(:sale)

      query = "INSERT INTO calls (id, caller_id, caller_name, notes, organization_id, sale) VALUES (#{id}, #{caller_id}, #{caller_name}, #{notes}, #{organization_id}, #{sale})"
      execute(query)
    end


    def quote(value)
      value.nil? ? '' : "'#{value}'"
    end

    def execute(query)
      Broker.log(query)
      Broker.cassandra.execute(query)
    end

  end
end