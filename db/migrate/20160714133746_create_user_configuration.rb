class CreateUserConfiguration < ActiveRecord::Migration
  def change
    create_table :user_configurations do |t|
      t.string :value
      t.string :key
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
