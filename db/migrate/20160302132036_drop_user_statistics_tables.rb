class DropUserStatisticsTables < ActiveRecord::Migration[4.2]
  def change
    drop_table :statistics_data_values_for_companies
    drop_table :statistics_data_names_for_companies
  end
end
