class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.string :name, null: false
      t.integer :direction, null: false, default: 0
    end
  end
end
