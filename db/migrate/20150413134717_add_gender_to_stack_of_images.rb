class AddGenderToStackOfImages < ActiveRecord::Migration[4.2]
  def change
    add_column :stack_of_images, :gender, :integer
  end
end
