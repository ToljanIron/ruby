class AddBrotherGaugeToAlgorithms < ActiveRecord::Migration[4.2]
  def change
    add_column :algorithms, :comparrable_gauge_id, :integer
  end
end
