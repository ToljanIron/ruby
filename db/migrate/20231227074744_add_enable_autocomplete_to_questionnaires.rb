class AddEnableAutocompleteToQuestionnaires < ActiveRecord::Migration[6.1]
  def change
    add_column :questionnaires, :snowball_enable_autocomplete, :bool, default: false
  end
end
