class CreateApiClientTaskDefinitions < ActiveRecord::Migration
  def change
    create_table :api_client_task_definitions do |t|
      t.string  :name
      t.string  :script_path
      t.timestamps null: false
    end
  end
end
