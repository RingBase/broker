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
      # Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
      Broker.cassandra = Cassandra.new(keyspace, "#{host}:#{port}", :connect_timeout => 10000)
      puts "Connected to cassandra #{host}, #{keyspace}"
      # delete_calls
    end

    def delete_calls
      # Delete all calls
      Broker.cassandra.get_range_keys(:Calls).each { |call_key| Broker.cassandra.remove(:Calls,call_key) }
      puts "delete calls"
    end

    def get_call_info(id)
      call1 = Broker.cassandra.get(:Calls,id)
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
      # execute("SELECT * FROM Calls WHERE called_national_number = '#{organization_pilot_number}'").to_a
      # selection = Broker.cassandra.get_range_keys(:Calls)
      calls  = []
      calls <<  {
        call_uuid: 'f0b228d0-ca7c-11e3-9c1a-0800200c9a66',
        called_country_code: 1,
        called_national_number: '8053945121',
        caller_name: 'Andrew Berls',
        calling_country_code: 1,
        calling_national_number: '7073227256',
        notes: '',
        sale_amount: 0,
        sale_currency: 'USD',
        state: 'parked',
        city: 'Santa Barbara',
        start_time: 1400021307
      }
      calls <<  {
        call_uuid: 'a40e3016-d4a0-4e38-b293-0741528295a0',
        called_country_code: 1,
        called_national_number: '8053945121',
        caller_name: 'Alex Wood',
        calling_country_code: 1,
        calling_national_number: '8054058403',
        notes: '',
        sale_amount: 0,
        sale_currency: 'USD',
        state: 'bridged',
        city: 'Santa Barbara',
        start_time: 1400019858
      }
      calls <<  {
        call_uuid: 'a30e3016-d4a0-4e38-b293-0741528295a0',
        called_country_code: 1,
        called_national_number: '8053945121',
        caller_name: 'Pete Cruz',
        calling_country_code: 1,
        calling_national_number: '5598275517',
        notes: '',
        sale_amount: 0,
        sale_currency: 'USD',
        state: 'parked',
        city: 'San Francisco',
        start_time: 1400019858
      }
      # Broker.cassandra.each(:calls) do |id|
      #   call = Broker.cassandra.get(:calls,id)
      #   call["id"] = id
      #   calls << call
      # end
      # Broker.log(calls)
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
