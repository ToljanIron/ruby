require 'spec_helper'
include SessionsHelper

describe ApplicationController, type: :controller do
  before do
    EventType.create!(name: 'ERROR')
    @user = User.new(first_name: 'name', email: 'user@company.com', password: 'qwe123', password_confirmation: 'qwe123', tmp_password: '123123')
    @user_with_token = User.new(first_name: 'name_token', email: 'user_token@company.com', password: 'qwe123', password_confirmation: 'qwe123', password_reset_token: '123', password_reset_token_expiry: DateTime.now + 1.week)
    @invalid_user = User.new(first_name: 'name2', email: 'user2@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @user.save!
    @user_with_token.save!
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'show_mobile' do
    it 'should deny un-authenticate questionnaire participant' do
      res = get "show_mobile", {token: "QQQ"}
      expect( res.body ).to include('Failed')
      expect( res.status ).to eq(200)
    end

    it 'should be able to authenticate a questionnaire participant' do
      allow_any_instance_of(QuestionnaireParticipant).to receive(:gt_locale).and_return(:en)
      emp = FactoryGirl.create(:employee, company_id: 0)
      QuestionnaireParticipant.create!(questionnaire_id: 1, employee_id: emp.id, token: 'QQQ')
      res = get "show_mobile", {token: "QQQ"}
      expect( res.body ).not_to include('Failed')
      expect( res.status ).to eq(200)
    end
  end
end
