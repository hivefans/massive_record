require 'massive_record/spec/support/simple_database_cleaner'

module SetUpHbaseConnectionBeforeAll
  extend ActiveSupport::Concern

  included do
    before(:all) do
      unless @connection
        @connection_configuration = {:host => MR_CONFIG['host'], :port => MR_CONFIG['port']}
        MassiveRecord::ORM::Base.connection_configuration = @connection_configuration
        @connection = MassiveRecord::Wrapper::Connection.new(@connection_configuration)
        @connection.open
      end
    end
  end
end

module SetTableNamesToTestTable
  extend ActiveSupport::Concern

  included do
    include MassiveRecord::Rspec::SimpleDatabaseCleaner

    after do
      MassiveRecord::ORM::Base.reset_connection!
      MassiveRecord::ORM::Base.descendants.each { |klass| klass.unmemoize_all }
    end
  end
end


module CreatePersonBeforeEach
  extend ActiveSupport::Concern

  included do
    include SetUpHbaseConnectionBeforeAll
    include SetTableNamesToTestTable

    before do
      @table = MassiveRecord::Wrapper::Table.new(@connection, Person.table_name)
      @table.column_families.create(:info)
      @table.save
      
      @row = MassiveRecord::Wrapper::Row.new
      @row.id = "ID1"
      @row.values = {:info => {:name => "John Doe", :email => "john@base.com", :age => "20"}}
      @row.table = @table
      @row.save
    end
  end
end
