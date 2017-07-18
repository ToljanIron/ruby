class FixName < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :name, :first_name
    add_column :users, :last_name, :string
    add_column :users, :active, :boolean, default: true
  end
end
