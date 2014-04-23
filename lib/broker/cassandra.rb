module Broker
  module Cassandra
    extend self


    def connect!(options={})
      host     = options.delete(:host)
      keyspace = options.delete(:keyspace)
      Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
    end


    # TODO: this will need to take parameters, ex: organization_id
    def get_calls_for_organization(organization_id)
      calls = []
      rows = execute("Select * from calls where organization_id = #{organization_id}")
      rows.each do |row|
        calls << row
      end
      calls
    end


    # TODO: remove this
    def insert_call(options={})
      id              = options.delete(:id)
      name            = quote(options.delete(:name))
      city            = quote(options.delete(:city))
      number          = quote(options.delete(:number))
      notes           = quote(options.delete(:notes))
      organization_id = options.delete(:organization_id) # necessary?
      sale            = options.delete(:sale)
      status          = options.delete(:status)

      query = "INSERT INTO calls (id, name, city, number, notes, organization_id, sale, status) VALUES (#{id}, #{name}, #{city}, #{number}, #{notes}, #{organization_id}, #{sale}, #{status})"
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
