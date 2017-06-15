class AddExternalIdToGroups < ActiveRecord::Migration
  def up
    add_column :groups, :external_id, :string
    Group.update_all('external_id=name')
  end

  def down
    remove_column :groups, :external_id
  end
end
