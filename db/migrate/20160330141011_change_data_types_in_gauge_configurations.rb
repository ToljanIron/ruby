class ChangeDataTypesInGaugeConfigurations < ActiveRecord::Migration[4.2]
  def self.up
    postgresql_exists = defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    is_postgresql = postgresql_exists.nil? ? false : ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    if is_postgresql
      puts "Altering table using Pstgresql syntax"
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_value TYPE float USING (minimum_value::float)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_value TYPE float USING (maximum_value::float)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_area TYPE float USING (minimum_area::float)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_area TYPE float USING (minimum_area::float)'
      return
    end

    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::SQLServerAdapter
      puts "Altering table using SQL Server syntax"
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_value DECIMAL (5,2)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_value DECIMAL (5,2)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_area DECIMAL (5,2)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_area DECIMAL (5,2)'
      return
    end

    raise "Unknown database adapter. Cannot alter table"
  end

  def self.down

    postgresql_exists = defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    is_postgresql = postgresql_exists.nil? ? false : ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    if is_postgresql
      puts "Altering table using Pstgresql syntax"
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_value TYPE integer USING (minimum_value::integer)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_value TYPE integer USING (maximum_value::integer)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_area TYPE integer USING (minimum_area::integer)'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_area TYPE integer USING (minimum_area::integer)'
      return
    end

    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::SQLServerAdapter
      puts "Altering table using SQL Server syntax"
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_value INTEGER'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_value INTEGER'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN minimum_area INTEGER'
      execute 'ALTER TABLE gauge_configurations ALTER COLUMN maximum_area INTEGER'
      return
    end

    raise "Unknown database adapter. Cannot alter table"
  end
end
