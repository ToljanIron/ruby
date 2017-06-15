class CreateMaritalStatuses < ActiveRecord::Migration
  def change
    create_table :marital_statuses do |t|
      t.string :name
      t.integer :color_id
      t.timestamps null: false
    end
    add_index :marital_statuses, [:name], unique: true
  end
end
