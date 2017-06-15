class AddUiefinitionToPin < ActiveRecord::Migration
  def change
    add_column :pins, :ui_definition, :string
  end
end
