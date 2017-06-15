class Meaningfulsqew < ActiveRecord::Migration
  def change
    add_column :algorithms, :meaningful_sqew, :integer
  end
end
