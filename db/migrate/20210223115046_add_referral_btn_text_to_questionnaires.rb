class AddReferralBtnTextToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
  	 add_column :questionnaires, :referral_btn_text, :string
  end
end
