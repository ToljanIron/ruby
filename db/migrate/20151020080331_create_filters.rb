class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.text :name
      t.integer :number_of_results

      t.timestamps null: false
    end
  end
end
