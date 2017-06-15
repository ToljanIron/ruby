class CreateFilterKeyword < ActiveRecord::Migration
  def change
    create_table :filter_keywords do |t|
      t.integer :company_id, null: false
      t.string :word, null: false

      t.timestamps null: false
    end
  end
end
