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
      # Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
      Broker.cassandra = Cassandra.new('Invoca','54.205.97.161:9160', :connect_timeout => 10000)
      puts "Connected to cassandra #{host}, #{keyspace}"
      test_function
    end

    def test_function
      #
      # Add sample calls
      #
      sample_calls = {
          "call_1" =>  {
              'state' => "parked",
              'calling_country_code' => "1",
              'calling_national_number' => "8056213030",
              'called_country_code'  => "1",
              'called_national_number' => "8003334444",
              'caller_name' => "Bob Smith",
              'notes' => "Here are some\nmulti-line notes.",
              'sale_currency' => "USD",
              'sale_amount' => "25.32"
          },
          "call_2" =>  {
              'call_uuid' => "call_2",
              'state' => "bridging",
              'calling_country_code' => "1",
              'calling_national_number' => "8056213030",
              'called_country_code'  => "1",
              'called_national_number' => "8003334444",
              'caller_name' => "Bob Smith",
              'notes' => "Here are some\nmulti-line notes.",
              'sale_currency' => "USD",
              'sale_amount' => "25.32"
          },
          "call_3" =>  {
              'call_uuid' => "call_3",
              'state' => "stopped",
              'calling_country_code' => "1",
              'calling_national_number' => "8056213030",
              'called_country_code'  => "1",
              'called_national_number' => "8003334444",
              'caller_name' => "Bob Smith",
              'notes' => "Here are some\nmulti-line notes.",
              'sale_currency' => "USD",
              'sale_amount' => "25.32"
          },
      }

      # sample_calls.each { |key,values| Broker.cassandra.insert(:Calls, key,values) }


      # Read all calls
      all_calls = Broker.cassandra.get_range(:Calls)
      puts "All Calls:"
      puts "-----------------------------------------"
      puts all_calls

      # Read one call
      call1 = Broker.cassandra.get(:Calls,"call_1")
      puts "One call:"
      puts "-----------------------------------------"
      puts call1


      # Delete all calls
      # Broker.cassandra.get_range_keys(:Calls).each { |call_key| Broker.cassandra.remove(:Calls,call_key) }
      # puts "delete calls"
    end

    def get_data(id)
      call1 = Broker.cassandra.get(:Calls,id)
      puts "One call:"
      puts "-----------------------------------------"
      puts call1
      call1
    end

    # TODO: this will need to take parameters, ex: organization_id

    # Retrieve an Array of call attributes hashes for an Organization with a given
    # pilot_number aka called_national_number
    #
    # organization_pilot_number - String phone number of the organization being called
    #
    # Returns Array[Hash]
    def get_calls_for_organization(organization_pilot_number)
      execute("SELECT * FROM Calls WHERE called_national_number = '#{organization_pilot_number}'").to_a
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
