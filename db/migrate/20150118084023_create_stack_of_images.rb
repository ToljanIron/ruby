class CreateStackOfImages < ActiveRecord::Migration[4.2]
  def change
    create_table :stack_of_images do |t|
      t.string :img_name
      t.timestamps 
    end
  end
end
