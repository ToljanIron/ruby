class AddActiveToPin < ActiveRecord::Migration
  def change
    add_column :pins, :active, :boolean, default: true
  end
end
