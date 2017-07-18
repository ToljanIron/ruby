class CreateTrusts < ActiveRecord::Migration[4.2]
  def change
    create_table :trusts do |t|
      t.integer :employee_id, null: false
      t.integer :trusted_id, null: false
      t.integer :trust_flag, default: 0

      t.timestamps null: false
    end
    add_index :trusts, :employee_id
    add_index :trusts, :trusted_id
  end
end
