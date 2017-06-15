class CreateQualifications < ActiveRecord::Migration
  def change
    create_table :qualifications do |t|
      t.integer :company_id,  null: false
      t.string  :name,        null: false
    end
  end
end
