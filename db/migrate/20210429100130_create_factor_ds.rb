class CreateFactorDs < ActiveRecord::Migration[5.2]
  def change
    create_table :factor_ds do |t|
      t.string :name
      t.integer :company_id
      t.integer :color_id

      t.timestamps
    end
  end
end
