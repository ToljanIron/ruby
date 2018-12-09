class AddSetupStateToCompanies < ActiveRecord::Migration[5.1]
  def up
    add_column :companies, :setup_state, :integer, default: 0
  end

  def down
    remove_column :companies, :setup_state
  end
end
