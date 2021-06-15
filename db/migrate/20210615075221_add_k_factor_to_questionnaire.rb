class AddKFactorToQuestionnaire < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :k_factor, :decimal, :default => 1
  end
end
