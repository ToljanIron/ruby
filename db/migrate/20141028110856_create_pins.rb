class CreatePins < ActiveRecord::Migration
  def change
    create_table :pins do |t|
      t.integer :company_id, null: false
      t.string :name
      t.string :definition
      t.column :status, :integer, default: 0

      t.timestamps
    end
  end
end
