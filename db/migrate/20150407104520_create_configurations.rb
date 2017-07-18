class CreateConfigurations < ActiveRecord::Migration[4.2]
  def change
    create_table :configurations do |t|
      t.string :value
      t.string :name
      t.timestamps null: false
    end
  end
end
