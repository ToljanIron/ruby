class AddUiefinitionToPin < ActiveRecord::Migration[4.2]
  def change
    add_column :pins, :ui_definition, :string
  end
end
