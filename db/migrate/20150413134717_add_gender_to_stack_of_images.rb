class AddGenderToStackOfImages < ActiveRecord::Migration
  def change
    add_column :stack_of_images, :gender, :integer
  end
end
