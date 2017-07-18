class CreateWordCloud < ActiveRecord::Migration[4.2]
  def change
    create_table :word_clouds do |t|
      t.integer :company_id, null: false
      t.integer :snapshot_id, null: false
      t.integer :group_id, null: false
      t.string  :word
      t.integer :count , default: 0

      t.timestamps null: true
    end
  end
end
