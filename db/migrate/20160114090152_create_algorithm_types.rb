class CreateAlgorithmTypes < ActiveRecord::Migration
  def change
    create_table :algorithm_types do |t|
      t.string :name

      t.timestamps null: true
    end
  end
end
