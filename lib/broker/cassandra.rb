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


    # organization_pilot_number - String phone number of the organization being called
    def get_calls_for_organization(organization_pilot_number)
      calls = []
      rows = execute("SELECT * FROM Calls WHERE called_national_number = '#{organization_pilot_number}'")
      rows.each do |row|
        calls << row
      end
      calls
    end


    def insert_call(options={})
      call_uuid = options.delete(:call_uuid)
      call_attributes = options.values_at(*CALL_FIELDS.map(&:to_sym))
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
