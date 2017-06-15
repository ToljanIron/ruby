require 'spec_helper'

describe 'SessionsController', type: :request do
  describe 'api_signin' do
    PASSWORD = 'A!a123'
    COMPANY = Company.create(name: 'company')
    def user_with_role(role)
      return FactoryGirl.create(:user, password: PASSWORD, password_confirmation: PASSWORD, role: role, company_id: COMPANY.id)
    end

    def params_for(user)
      return { email: user.email, password: PASSWORD }
    end

    before do
      Rake::Task['db:seed:event_types'].invoke
    end

    context ', signin-signout flow with valid users' do
      describe ', when user is admin' do
        before do
          user = user_with_role('admin')
          post '/API/signin', params_for(user)
        end
        it 'should log in' do
          expect(response.status).to be 200
        end
        it 'should reach company page' do
          get '/'
          expect(response.location).to include('v2')
        end
        it 'should log out' do
          get '/signout'
          expect(response).to redirect_to signin_path
        end
      end

      describe ', when user is HR and reach company_page' do
        before do
          user = user_with_role('hr')
          post '/API/signin', params_for(user)
        end
        it 'should log in' do
          expect(response.status).to be 200
        end
        it 'should reach company page' do
          get '/'
          expect(response.location).to include('v2')
        end
        it 'should not reach admin_page' do
          get '/admin_page'
          expect(response).to redirect_to root_path
        end
        it 'should log out' do
          get '/signout'
          expect(response).to redirect_to signin_path
        end
      end

      describe ', when user is employee and reach employee_page' do
        before do
          user = user_with_role('emp')
          post '/API/signin', params_for(user)
        end
        it 'should log in' do
          expect(response.status).to be 200
        end
        it 'should not reach company page' do
          get '/'
          expect(response).to redirect_to v2_path
        end
        it 'should not reach admin_page' do
          get '/admin_page'
          expect(response.status).to be 200
        end
        it 'should log out' do
          get '/signout'
          expect(response).to redirect_to signin_path
        end
      end
    end
  end
end
