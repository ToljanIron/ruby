class AddEnglishNameToGroups < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :english_name, :string, default: nil
  end

  def down
    remove_column :groups, :english_name
  end
end
