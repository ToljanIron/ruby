class CreateReoccurrence < ActiveRecord::Migration[4.2]
  def change
    create_table :reoccurrences do |t|
      t.bigint :run_every_by_minutes, null: false
      t.bigint :fail_after_by_minutes, null: false

      t.timestamps
    end
  end
end
