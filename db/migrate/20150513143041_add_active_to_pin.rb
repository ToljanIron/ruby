class AddActiveToPin < ActiveRecord::Migration[4.2]
  def change
    add_column :pins, :active, :boolean, default: true
  end
end
