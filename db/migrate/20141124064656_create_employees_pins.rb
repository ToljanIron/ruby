class CreateEmployeesPins < ActiveRecord::Migration[4.2]
  def change
    create_table :employees_pins, id: false do |t|
      t.integer  :pin_id,       null: false
      t.integer  :employee_id,  null: false

      t.timestamps
    end
  end
end
