class CreateNetworkSnapshotNodes < ActiveRecord::Migration[4.2]
  def change
    create_table :network_snapshot_nodes do |t|
      t.integer :employee_from_id, 	null: false
      t.integer :employee_to_id, 		null: false
      t.integer :snapshot_id,       null: false
      t.integer :weight, 	default: 	0
      t.integer :n1, 			default: 	0
      t.integer :n2, 			default: 	0
      t.integer :n3, 			default: 	0
      t.integer :n4, 			default: 	0
      t.integer :n5, 			default: 	0
      t.integer :n6, 			default: 	0
      t.integer :n7, 			default: 	0
      t.integer :n8, 			default: 	0
      t.integer :n9,			default: 	0
      t.integer :n10, 		default: 	0
      t.integer :n11, 		default: 	0
      t.integer :n12, 		default: 	0
      t.integer :n13, 		default: 	0
      t.integer :n14, 		default: 	0
      t.integer :n15, 		default: 	0
      t.integer :n16, 		default: 	0
      t.integer :n17, 		default: 	0
      t.integer :n18, 		default: 	0

      t.timestamps
    end
    add_index :network_snapshot_nodes, [:snapshot_id], name: 'index_snapshot_nodes_on_snapshot_id'
    add_index :network_snapshot_nodes, [:employee_from_id], name: 'index_snapshot_nodes_on_employee_from_id'
    add_index :network_snapshot_nodes, [:employee_to_id], name: 'index_snapshot_nodes_on_employee_to_id'
  end
end
