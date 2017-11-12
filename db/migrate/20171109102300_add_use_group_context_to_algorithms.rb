class AddUseGroupContextToAlgorithms < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :use_group_context, :boolean, default: true
  end
end
