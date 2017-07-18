class CreateAdvice < ActiveRecord::Migration[4.2]
  def change
    create_table :advices do |t|
      t.integer :employee_id, null: false
      t.integer :advicee_id,  null: false
      t.integer :advice_flag, null: false, default: 0

      t.timestamps
    end
    add_index :advices, [:employee_id], name: 'index_advices_on_employee_id'
    add_index :advices, [:advicee_id],   name: 'index_advices_on_friend_id'
  end
end
