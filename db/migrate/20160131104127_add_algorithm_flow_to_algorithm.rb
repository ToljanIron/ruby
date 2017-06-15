class AddAlgorithmFlowToAlgorithm < ActiveRecord::Migration
  def change
    add_column :algorithms, :algorithm_flow_id, :integer, null: false, default: 1
  end
end
