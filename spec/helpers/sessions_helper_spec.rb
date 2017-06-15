require 'spec_helper.rb'
describe SessionsHelper, type: :helper do
  before do
    @user = User.new(first_name: 'name', email: 'user@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @invalid_user = User.new(first_name: 'name2', email: 'user2@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @user.save!
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @user }

  describe ', sign_in' do
    it ', vaild user should be able to signin' do
      log_in @user
      expect(current_user).to eq(@user)
    end
  end

  describe 'client_auth' do
    it 'should auth by token after signin' do
      log_in @user
      self.current_user = nil
      client_auth @user[:remember_token]
      expect(current_user).to eq(@user)
    end

    it 'should auth by token after signin' do
      log_in @user
      current_user = nil
      client_auth 'invalid token'
      expect(current_user).not_to eq(@user)
    end
  end

end
