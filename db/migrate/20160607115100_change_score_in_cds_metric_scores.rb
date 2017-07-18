class ChangeScoreInCdsMetricScores < ActiveRecord::Migration[4.2]
  def self.up
    postgresql_exists = defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    is_postgresql = postgresql_exists.nil? ? false : ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    if is_postgresql
      puts "Altering table using Pstgresql syntax"
      execute 'ALTER TABLE cds_metric_scores ALTER COLUMN score TYPE numeric(10,2) USING (score::numeric(10,2))'
      return
    end

    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::SQLServerAdapter
      puts "Altering table using SQL Server syntax"
      execute 'ALTER TABLE cds_metric_scores ALTER COLUMN score DECIMAL (10,2)'
      return
    end

    raise "Unknown database adapter. Cannot alter table"
  end

  def self.down

    postgresql_exists = defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    is_postgresql = postgresql_exists.nil? ? false : ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    if is_postgresql
      puts "Altering table using Pstgresql syntax"
      execute 'ALTER TABLE cds_metric_scores ALTER COLUMN score TYPE float USING (score::float)'
      return
    end

    if ActiveRecord::Base.connection.instance_of? ActiveRecord::ConnectionAdapters::SQLServerAdapter
      puts "Altering table using SQL Server syntax"
      execute 'ALTER TABLE cds_metric_scores ALTER COLUMN score DECIMAL(4,2)'
      return
    end

    raise "Unknown database adapter. Cannot alter table"
  end
end
