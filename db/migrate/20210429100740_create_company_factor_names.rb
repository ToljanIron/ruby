class CreateCompanyFactorNames < ActiveRecord::Migration[5.2]
  def change
    create_table :company_factor_names do |t|
      t.string :factor_name
      t.integer :company_id
      t.string :display_name
      t.integer :snapshot_id
      t.boolean :is_table

      t.timestamps
    end
  end
end
