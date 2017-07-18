class DropTableTrust < ActiveRecord::Migration[4.2]
  def change
    drop_table :trusts
  end
end
