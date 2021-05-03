class AddFactorColumnsToEmployee < ActiveRecord::Migration[5.2]
  def change
    add_column :employees, :factor_a_id, :integer
    add_column :employees, :factor_b_id, :integer
    add_column :employees, :factor_c_id, :integer
    add_column :employees, :factor_d_id, :integer
    add_column :employees, :factor_e_id, :integer
    add_column :employees, :factor_f_id, :integer
    add_column :employees, :factor_g_id, :integer

    add_column :employees, :factor_h, :string
    add_column :employees, :factor_i, :string
    add_column :employees, :factor_j, :string
  end
end