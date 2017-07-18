class CreateGroups < ActiveRecord::Migration[4.2]
  def change
    create_table :groups do |t|
      t.string      :name,        null: false
      t.integer     :company_id,  null: false
      t.integer     :parent_group_id
      t.integer     :color_id

      t.timestamps
    end
  end
end
