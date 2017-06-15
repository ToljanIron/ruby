class CreateAgeGroup < ActiveRecord::Migration
  def change
    create_table :age_groups do |t|
      t.string :name
      t.integer :color_id
      t.timestamps null: false
    end
    add_index :age_groups, [:name], unique: true
  end
end
