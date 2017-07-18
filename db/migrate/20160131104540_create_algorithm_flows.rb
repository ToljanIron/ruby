class CreateAlgorithmFlows < ActiveRecord::Migration[4.2]
  def change
    create_table :algorithm_flows do |t|
      t.string :name, null: false
    end
  end
end
