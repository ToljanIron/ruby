class CreateLanguages < ActiveRecord::Migration[4.2]
  def change
    create_table :languages, force: :cascade do |t|
      t.string :name, null: false
      t.integer :direction, null: false, default: 0
    end
  end
end