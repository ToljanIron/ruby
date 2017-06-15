require 'spec_helper'

describe User, type: :model do

  before do
    @user = User.new(first_name: 'Example', last_name: 'User', email: 'user@example.com',
                     password: 'foobar', password_confirmation: 'foobar')
  end

  subject { @user }

  it { is_expected.to respond_to(:first_name) }
  it { is_expected.to respond_to(:last_name) }
  it { is_expected.to respond_to(:email) }
  it { is_expected.to respond_to(:password_digest) }
  it { is_expected.to respond_to(:password) }
  it { is_expected.to respond_to(:password_confirmation) }
  it { is_expected.to respond_to(:remember_token) }
  it { is_expected.to respond_to(:authenticate) }
  it { is_expected.to be_valid }

  describe 'when email is not present' do
    before { @user.email = ' ' }
    it { is_expected.not_to be_valid }
  end

  describe 'when first name is too long' do
    before { @user.first_name = 'a' * 51 }
    it { is_expected.not_to be_valid }
  end

  describe 'when first name is too long' do
    before { @user.last_name = 'a' * 41 }
    it { is_expected.not_to be_valid }
  end

  describe 'when email format is invalid' do
    it 'should be invalid' do
      addresses = %w(user@foo,com user_at_foo.org example.user@foo.
                     foo@bar_baz.com foo@bar+baz.com)
      addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid
      end
    end
  end

  describe 'when email format is valid' do
    it 'should be valid' do
      addresses = %w(user@foo.COM A_US-ER@f.b.org frst.lst@foo.jp a+b@baz.cn)
      addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid
      end
    end
  end

  describe 'when email address is already taken' do
    before do
      user_with_same_email = @user.dup
      user_with_same_email.email = @user.email.upcase
      user_with_same_email.save
    end

    it { is_expected.not_to be_valid }
  end

  describe 'when password is not present' do
    before do
      @user = User.new(first_name: 'Example', last_name: 'User', email: 'user@example.com',
                       password: ' ', password_confirmation: ' ')
    end
    it { is_expected.not_to be_valid }
  end

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = 'mismatch' }
    it { is_expected.not_to be_valid }
  end

  describe "with a password that's too short" do
    before { @user.password = @user.password_confirmation = 'a' * 5 }
    it { is_expected.to be_invalid }
  end

  describe 'return value of authenticate method' do
    before do
      @user.save
      @found_user = User.find_by(email: @user.email)
    end

    describe 'with valid password' do
      #      it { should eq @found_user.authenticate(@user.password) }
    end

    describe 'with invalid password' do
      let(:user_for_invalid_password) { @found_user.authenticate('invalid') }

      it { is_expected.not_to eq user_for_invalid_password }
      specify { expect(user_for_invalid_password).to be_falsey }
    end
  end

  describe 'remember token' do
    before do
      @user[:email] += 'a'
      @user.save
    end

    describe '#remember_token' do
      subject { super().remember_token }
      it { is_expected.not_to be_blank }
    end
  end
end
