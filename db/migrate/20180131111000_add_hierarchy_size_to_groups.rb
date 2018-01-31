class AddHierarchySizeToGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :hierarchy_size,  :integer
  end

  def down
    remove_column :groups, :hierarchy
  end
end
