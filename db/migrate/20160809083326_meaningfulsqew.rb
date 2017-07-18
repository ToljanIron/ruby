class Meaningfulsqew < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :meaningful_sqew, :integer
  end
end
