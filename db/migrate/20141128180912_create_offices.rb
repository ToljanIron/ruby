class CreateOffices < ActiveRecord::Migration[4.2]
  def change
    create_table :offices do |t|
      t.integer :company_id,  null: false
      t.string  :name,        null: false
    end
  end
end
