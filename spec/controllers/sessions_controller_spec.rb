require 'spec_helper'
#require './spec/factories/company_factory.rb'
include SessionsHelper
describe SessionsController, type: :controller do
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
  describe ',redirect_to employee page ' do
    it ',can redirect to admin page when the user is admin ' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      res = post :employee_page
      expect(res.status).to eq(200)
    end
  end

  describe ',create - log in ' do
    it ',should log in with admin and redirect to  admin_page' do
      @user.role = ADMIN
      @user.save!
      res = post :api_signin, email: 'user@company.com', password: 'qwe123'
      expect(res.status).to eq(200)
      res2 = get :signin
      expect(res2).to redirect_to admin_page_path
    end

    it ',should log in with HR and redirect to root_page' do
      @user.role = HR
      @user.save!
      res = post :api_signin, email: 'user@company.com', password: 'qwe123'
      expect(res.status).to eq(200)
      res2 = get :signin
      expect(res2).to redirect_to root_path
    end

    it ',should log in with worng password and not redirect to home page' do
      @user.role = HR
      @user.save!
      session = { email: 'user@company.com', password: '123456' }
      post :create, session: session
      expect(response).not_to redirect_to root_path
    end

    it ',should log in with worng email and not redirect_to admin_page ' do
      @user.role = ADMIN
      @user.save!
      session = { email: 'admin@walla.com', password: 'qwe123' }
      post :create, session: session
      expect(response).not_to redirect_to employee_page_path
    end

    it ',should log in with wrong email and  redirect_to sign in ' do
      @user.role = ADMIN
      @user.save!
      res = post :api_signin, email: 'admin@walla.com', password: 'qwe123'
      expect(res.status).to eq(550)
      res2 = get :signin
      expect(res2).to render_template 'signin'
    end

=begin

    _TODO: domain check is dead code, should we remove it? US-12195

    it 'should redirect to request_google_access if gmail needs permission' do
      @user.role = ADMIN
      @user.company_id = 1
      @user.save!
      d = FactoryGirl.create(:domain, company_id: @user.company_id)
      FactoryGirl.create(:email_service, name: 'gmail', domain_id: d.id)
      session = { email: 'user@company.com', password: 'qwe123' }
      response = post :create, session: session
      expect(response).to redirect_to(controller: 'clients', action: 'request_google_access', domain_id: d.id)
    end

    it 'should redirect to domains_list gmail needs more than one permission' do
      @user.role = ADMIN
      @user.company_id = 1
      @user.save!
      d = FactoryGirl.create(:domain, company_id: @user.company_id)
      d2 = FactoryGirl.create(:domain, company_id: @user.company_id)
      FactoryGirl.create(:email_service, name: 'gmail', domain_id: d.id)
      FactoryGirl.create(:email_service, name: 'gmail', domain_id: d2.id)
      session = { email: 'user@company.com', password: 'qwe123' }
      response = post :create, session: session
      expect(response).to redirect_to domains_list_path
    end
=end

  end

  describe ',company_redirect' do
    it ',should update the company when the user is admin' do
      log_in_with_dummy_user_with_role(ADMIN, 2)
      session = { company_id: 1 }
      post :company_redirect,  session: session
      expect(User.find(current_user.id).company_id).to eq(1)
    end

    it ',should not updated the company when the user is not admin(hr)' do
      log_in_with_dummy_user_with_role(HR, 2)
      session = { company_id: 1 }
      expect { post :company_redirect,  session: session }.to raise_error(Pundit::NotAuthorizedError)
    end

    it ',should not updated the company when the user is not admin(emplyee)' do
      log_in_with_dummy_user_with_role(EMPLOYEE, 2)
      session = { company_id: 1 }
      response = post :company_redirect,  session: session
      expect(response).to render_template 'sessions/employee_page'
    end
  end

  describe 'api_signin with valid email/password' do
    it ', should return a tokoen' do
      res = post :api_signin, email: 'user@company.com', password: 'qwe123'
      expect(res.body).not_to be_nil
    end
    it ', should return a status 200' do
      res = post :api_signin, email: 'user@company.com', password: 'qwe123'
      expect(res.status).to eq(200)
    end
  end

  describe 'api_signin with invalid email/password' do
    it ', should not return a tokoen' do
      res = post :api_signin, email: 'invalid@company.com', password: 'invalid'
      expect(res.status).to eq(550)
    end
  end

  describe ',render forgot password ' do
    it ',render forgot password ' do
      get :forgot_password
      expect(response).to render_template 'forgot_password'
    end
  end

  describe ',render set password ' do
    it ',render set password ' do
      log_in_with_dummy_user_with_role(ADMIN, 2)
      get :set_password
      expect(response).to render_template 'set_password'
    end
    it ',render sign in ' do
      get :set_password
      expect(response).to redirect_to signin_path
    end
  end

  describe ',render reset password ' do
    it ',render reset password ' do
      get :reset_password, token: @user_with_token.password_reset_token
      expect(response).to render_template 'reset_password'
    end
    it ',render sign in ' do
      get :reset_password, token: '1234'
      expect(response).to redirect_to '/'
    end
  end
end
