class AddSnapshotIdToGroups < ActiveRecord::Migration
  def up
    add_column :groups, :snapshot_id, :integer
    Group.all.each { |g| set_default_snapshot(g) }
  end

  def down
    remove_column :groups, :snapshot_id
  end

  def set_default_snapshot(g)
    cid = Company.find(g.company_id).id
    sid = Snapshot.last_snapshot_of_company(cid)
    g.update(snapshot_id: sid)
    return sid
  end
end
