class AddBrotherGaugeToAlgorithms < ActiveRecord::Migration
  def change
    add_column :algorithms, :comparrable_gauge_id, :integer
  end
end
