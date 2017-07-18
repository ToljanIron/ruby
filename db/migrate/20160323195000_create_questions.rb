class CreateQuestions < ActiveRecord::Migration[4.2]
  def change
    create_table :questions do |t|
      t.integer :company_id
      t.string  :title
      t.text    :body
      t.integer :order
      t.integer :depends_on_question
      t.integer :min
      t.integer :max
      t.boolean :active

      t.timestamps null: false
    end
  end
end
