require 'securerandom'

module Broker
  module Cassandra
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
      Broker.cassandra = Cql::Client.connect(host: host, keyspace: keyspace)
    end


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
      Broker.log(query)
      Broker.cassandra.execute(query)
    end

  end
end
