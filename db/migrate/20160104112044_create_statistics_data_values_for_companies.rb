class CreateStatisticsDataValuesForCompanies < ActiveRecord::Migration
  def change
    create_table :statistics_data_values_for_companies do |t|
      t.integer 'company_id', null: false
      t.integer 'snapshot_id', nul: false
      t.integer 'statistics_data_names_for_companies_id', null: false
      t.integer 'value', null: false


      t.timestamps null: false
    end
  end
end
