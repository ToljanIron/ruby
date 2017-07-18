class CreateEmployeeAttributes < ActiveRecord::Migration[4.2]
  def change
    create_table :employee_attributes do |t|
      t.integer :employee_id
      t.integer :data_type, default: 0
      t.integer :snapshot_id
      t.string :data1
      t.string :data2
      t.string :data3
      t.string :data4
      t.string :data5

      t.timestamps null: false
    end
  end

  def down
    drop_talbe :employee_attributes
  end
end
