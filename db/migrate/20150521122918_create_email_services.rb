class CreateEmailServices < ActiveRecord::Migration[4.2]
  def change
    create_table :email_services do |t|
      t.integer :domain_id, nul: false
      t.string :name,       nul: false
      t.string :refresh_token

      t.timestamps null: false
    end
  end
end
