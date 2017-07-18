class CreateStatisticsDataNamesForCompanies < ActiveRecord::Migration[4.2]
  def change
    create_table :statistics_data_names_for_companies do |t|
      t.integer 'company_id', null: false
      t.integer 'question_index', null: false
      t.integer 'name', null: false

      t.timestamps null: false
    end
  end
end
