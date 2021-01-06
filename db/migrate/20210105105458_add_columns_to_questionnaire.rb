class AddColumnsToQuestionnaire < ActiveRecord::Migration[5.2]
  def change
  	add_column :questionnaires, :logo_url, :string
  	add_column :questionnaires, :close_title, :string
  	add_column :questionnaires, :close_sub_title, :string
  	add_column :questionnaires, :is_referral_btn, :boolean, default: false
  	add_column :questionnaires, :referral_btn_url, :string
  	add_column :questionnaires, :referral_btn_id, :string
  	add_column :questionnaires, :referral_btn_color, :string
  end
end