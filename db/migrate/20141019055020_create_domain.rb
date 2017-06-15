class CreateDomain < ActiveRecord::Migration
  def change
    create_table :domains do |t|
      t.integer :company_id, null: false
      t.string :domain, null: false
      t.timestamps
    end
  add_index :domains, :domain, unique: true
  end
end
