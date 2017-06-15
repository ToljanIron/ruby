class CreateColors < ActiveRecord::Migration
  def change
    create_table :colors do |t|
      t.string :rgb

      t.timestamps null: false
    end
    add_index :colors, :rgb, unique: true
  end
end
