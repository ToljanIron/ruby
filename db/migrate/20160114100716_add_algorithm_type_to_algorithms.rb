class AddAlgorithmTypeToAlgorithms < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :algorithm_type_id, :integer
  end
end
