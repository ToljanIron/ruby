class CreateJobTitles < ActiveRecord::Migration[4.2]
  def change
    create_table :job_titles do |t|
      t.string :name
      t.integer :color_id
      t.integer :company_id
      t.timestamps null: false
    end
  end
end
