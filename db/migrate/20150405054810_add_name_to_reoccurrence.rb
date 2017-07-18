class AddNameToReoccurrence < ActiveRecord::Migration[4.2]
  def change
    add_column :reoccurrences, :name, :string
  end
end
