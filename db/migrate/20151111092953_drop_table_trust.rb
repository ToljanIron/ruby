class DropTableTrust < ActiveRecord::Migration
  def change
    drop_table :trusts
  end
end
