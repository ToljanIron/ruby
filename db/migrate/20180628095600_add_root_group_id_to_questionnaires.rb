class AddRootGroupIdToQuestionnaires < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaires, :root_group_id, :integer
  end

  def down
    remove_column :questionnaires, :root_group_id
  end
end
