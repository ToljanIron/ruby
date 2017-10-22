class FixExteranlIdConstraintInGroups < ActiveRecord::Migration[4.2]
  def up
    #add_index :groups, [:external_id, :snapshot_id, :company_id], name: 'index_groups_on_ext_and_snapshot_id_and_company_id', unique: true
  end
end
