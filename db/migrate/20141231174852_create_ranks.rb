class CreateRanks < ActiveRecord::Migration[4.2]
  def change
    create_table :ranks do |t|
      t.string :name
      t.integer :color_id
      t.timestamps null: false
    end
    add_index :ranks, [:name], unique: true
  end
end
