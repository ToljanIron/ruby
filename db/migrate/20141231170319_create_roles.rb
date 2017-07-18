class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.integer :company_id
      t.string :name
      t.integer :color_id
      t.timestamps null: false
    end
    add_index :roles, [:company_id, :name], unique: true
  end
end
