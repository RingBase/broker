require 'securerandom'
require 'cassandra'

module Broker
  module Cassandra2
    extend self

    CALL_FIELDS = %w(
      state
      calling_country_code
      calling_national_number
      called_country_code
      called_national_number
      caller_name
      notes
      sale_currency
      sale_amount
    )

    def connect!(options={})
      host     = options.delete(:host)
      keyspace = options.delete(:keyspace)
      port     = options.delete(:port)
      #Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
      Broker.cassandra = Cassandra.new(keyspace, "#{host}:#{port}", :connect_timeout => 10000)
      puts "Connected to cassandra #{host}, #{keyspace}"
    end

    # def delete_calls
    #   # Delete all calls
    #   Broker.cassandra.get_range_keys(:Calls).each { |call_key| Broker.cassandra.remove(:Calls,call_key) }
    #   puts "delete calls"
    # end

    def get_call_info(id)
      Broker.cassandra.get(:Calls,id)
    end

    # TODO: this will need to take parameters, ex: organization_id

    # Retrieve an Array of call attributes hashes for an Organization with a given
    # pilot_number aka called_national_number
    #
    # organization_pilot_number - String phone number of the organization being called
    #
    # Returns Array[Hash]
    def get_calls_for_organization(organization_pilot_number)
      #result = execute("SELECT * FROM Calls WHERE called_national_number = '#{organization_pilot_number}'").to_a
      #p result

      calls  = []
      Broker.cassandra.each(:Calls) do |id|
       call = Broker.cassandra.get(:Calls,id)
       call['id'] = id
       calls << call
      end

      calls
    end

    # Insert a call into Cassandra for testing
    #
    # attrs - Hash of call attributes, all required (see CALL_FIELDS)
    #
    # Returns nothing
    def insert_call(attrs={})
      call_uuid = quote(SecureRandom.uuid)
      call_attributes = attrs.values_at(*CALL_FIELDS.map(&:to_sym))
                               .map { |attr| quote(attr) }

      query = <<-EOS
        INSERT INTO Calls (call_uuid, #{CALL_FIELDS.join(',')})
        VALUES (#{call_uuid}, #{call_attributes.join(',')});
      EOS
      execute(query)
    end

    private

    def quote(value)
      value.nil? ? '' : "'#{value}'"
    end

    def execute(query)
      Broker.log("[Cassandra] '#{query}'")
      Broker.cassandra.execute(query)
    end
  end
end
