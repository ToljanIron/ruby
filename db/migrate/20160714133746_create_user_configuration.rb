class CreateUserConfiguration < ActiveRecord::Migration[4.2]
  def change
    create_table :user_configurations do |t|
      t.string :value
      t.string :key
      t.integer :user_id
      t.timestamps null: false
    end
  end
end
