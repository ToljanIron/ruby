require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper
describe UsersController, type: :controller do
  ADMIN = 0
  HR = 1
  EMPLOYEE = 2
  COMPANY_1 = 1
  COMPANY_2 = 2
  before do
    EventType.create!(name: 'ERROR')
    @user = User.new(first_name: 'name', email: 'user@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @user_with_token = User.new(first_name: 'name_token', email: 'user_token@company.com', password: 'qwe123', password_confirmation: 'qwe123', password_reset_token: '123', password_reset_token_expiry: DateTime.now + 1.week)
    @invalid_user = User.new(first_name: 'name2', email: 'user2@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @user.save!
    @user_with_token.save!
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'user forgot password ' do
    it 'should send the user mail with link + token for reset ' do
      res = post :user_forgot_password, data: 'user@company.com', password: 'qwe123'
      @user.reload
      expect(@user.password_reset_token).not_to be_nil
      expect(@user.password_reset_token_expiry).not_to be_nil
      expect(res.status).to eq(200)
    end
    it 'should fail user not exist ' do
      res = post :user_forgot_password, data: 'user2@company.com', password: 'qwe123'
      expect(@user.password_reset_token).to be_nil
      expect(@user.password_reset_token_expiry).to be_nil
      expect(res.status).to eq(550)
    end
  end

  describe 'update_reset_new_password ' do
    it ',should reset the user password ' do
      original_pass_digest = @user_with_token.password_digest
      res = post :update_reset_new_password, password: '123qwe', password_confirmation: '123qwe', token: @user_with_token.password_reset_token
      @user_with_token.reload
      expect(@user_with_token.password_reset_token_expiry).to be < DateTime.now + 1.week
      expect(@user_with_token.password_digest).not_to eq(original_pass_digest)
      expect(res.status).to eq(200)
    end
    it 'should fail password don\'t match ' do
      res = post :update_reset_new_password, password: '123qwe', password_confirmation: '1234qwe', token: @user_with_token.password_reset_token
      @user_with_token.reload
      expect(res.status).to eq(401)
    end
    it 'should fail user not exist ' do
      res = post :update_reset_new_password, password: '123qwe', password_confirmation: '123qwe', token: '1234'
      @user_with_token.reload
      expect(res).to redirect_to '/'
    end
  end

  describe 'update_set_new_password ' do
    it ',should set the user new password ' do
      @request.session['user_id'] = 1
      original_pass_digest = @user.password_digest
      res = post :update_set_new_password, password: '123qwe', password_confirmation: '123qwe'
      @user.reload
      expect(@user.password_digest).not_to eq(original_pass_digest)
      expect(res.status).to eq(200)
    end
    it 'should fail password don\'t match ' do
      res = post :update_set_new_password, password: '123qwe', password_confirmation: '1234qwe'
      @user.reload
      expect(res.status).to eq(401)
    end
    it 'should fail user not exist ' do
      @request.session['user_id'] = 10
      res = post :update_set_new_password, password: '123qwe', password_confirmation: '123qwe'
      @user.reload
      expect(res).to render_template 'sessions/signin'
    end
  end
end
