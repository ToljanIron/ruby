class AddAlgorithmFlowToAlgorithm < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :algorithm_flow_id, :integer, null: false, default: 1
  end
end
