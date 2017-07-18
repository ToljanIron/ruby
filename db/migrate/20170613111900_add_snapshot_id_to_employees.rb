class AddSnapshotIdToEmployees < ActiveRecord::Migration[4.2]
  def up
    add_column :employees, :snapshot_id, :integer
    Employee.all.each { |emp| set_default_snapshot(emp) }
  end

  def down
    remove_column :employees, :snapshot_id
  end

  def set_default_snapshot(emp)
    cid = Company.find(emp.company_id).id
    sid = Snapshot.last_snapshot_of_company(cid)
    emp.update(snapshot_id: sid)
    return sid
  end
end
