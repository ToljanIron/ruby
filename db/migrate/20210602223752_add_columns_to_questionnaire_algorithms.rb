class AddColumnsToQuestionnaireAlgorithms < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaire_algorithms, :param_a_score, :decimal
    add_column :questionnaire_algorithms, :param_b_score, :decimal
    add_column :questionnaire_algorithms, :param_c_score, :decimal
    add_column :questionnaire_algorithms, :param_d_score, :decimal
    add_column :questionnaire_algorithms, :param_e_score, :decimal
    add_column :questionnaire_algorithms, :param_f_score, :decimal
    add_column :questionnaire_algorithms, :param_g_score, :decimal
    add_column :questionnaire_algorithms, :param_h_score, :decimal
    add_column :questionnaire_algorithms, :param_i_score, :decimal
    add_column :questionnaire_algorithms, :param_j_score, :decimal
  end
end
