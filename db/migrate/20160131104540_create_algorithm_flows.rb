class CreateAlgorithmFlows < ActiveRecord::Migration
  def change
    create_table :algorithm_flows do |t|
      t.string :name, null: false
    end
  end
end
