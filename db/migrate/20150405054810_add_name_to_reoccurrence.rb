class AddNameToReoccurrence < ActiveRecord::Migration
  def change
    add_column :reoccurrences, :name, :string
  end
end
