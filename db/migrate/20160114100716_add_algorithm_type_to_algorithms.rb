class AddAlgorithmTypeToAlgorithms < ActiveRecord::Migration
  def change
    add_column :algorithms, :algorithm_type_id, :integer
  end
end
