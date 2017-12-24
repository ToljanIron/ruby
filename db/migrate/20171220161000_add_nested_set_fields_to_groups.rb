class AddNestedSetFieldsToGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :nsleft,  :integer
    add_column :groups, :nsright, :integer

    add_index :groups, [:nsleft, :nsright], name: :index_groups_on_nsleft_and_nsright
  end

  def down
    remove_index :groups, name: :index_groups_on_nsleft_and_nsright

    remove_column :groups, :nsleft
    remove_column :groups, :nsright
  end
end
