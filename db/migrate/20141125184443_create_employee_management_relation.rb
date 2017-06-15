class CreateEmployeeManagementRelation < ActiveRecord::Migration
  def change
    create_table :employee_management_relations do |t|
      t.integer       :manager_id,     null: false
      t.integer       :employee_id,   null: false
      t.integer       :relation_type, null: false

      t.timestamps
    end
    add_index :employee_management_relations, [:manager_id], name: 'index_employee_managment_relations_on_maneger_id'
  end
end
