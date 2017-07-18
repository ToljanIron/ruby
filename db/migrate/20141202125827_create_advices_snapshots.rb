class CreateAdvicesSnapshots < ActiveRecord::Migration[4.2]
	def change
		create_table :advices_snapshots do |t|
			t.integer :employee_id, null: false
			t.integer :advicee_id, null: false
			t.integer :snapshot_id, null: false
			t.integer :advice_flag, default: 0
			t.timestamps
		end
		#add_index :advices, [:employee_id], name: 'index_advices_snapshots_on_employee_id'
		add_index :advices, [:advicee_id],   name: 'index_advices_snapshots_on_advicee_id'
	end
    #add_index :friendships, [:snapshot_id], name: 'index_friendships_snapshots_on_snapshot_id'
end
