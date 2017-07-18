class CreateCompanyConfigurationTables < ActiveRecord::Migration[4.2]
  def change
    create_table :company_configuration_tables do |t|
      t.string :key
      t.string :value
      t.integer :comp_id

      t.timestamps null: false
    end
  end
end
