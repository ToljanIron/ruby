class AddCompanyStatistics < ActiveRecord::Migration[4.2]
  def change
    create_table :company_statistics do |t|
      t.integer :snapshot_id
      t.string  :statistic_title
      t.string :statistic_data
      t.string :icon_path
      t.string :tooltip
      t.string :link_to
      t.integer :display_order
    end
  end
end
