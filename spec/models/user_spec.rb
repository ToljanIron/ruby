require 'spec_helper'

describe User, type: :model do

  before do
    @user = User.new(first_name: 'Example', last_name: 'User', email: 'user@example.com',
                     password: 'foobar', password_confirmation: 'foobar')
  end

  subject { @user }

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

  describe "when password doesn't match confirmation" do
    before { @user.password_confirmation = 'mismatch' }
    it { is_expected.not_to be_valid }
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

  describe 'can_login?' do
    user = nil
    max_attempts = 3
    lock_delay = 300

    before :each do
      User.delete_all
      user = User.create!(email: 'e@mail.com', company_id: 999, password: '12345678')
    end

    it 'not enough time passed since user was locked' do
      user.is_locked_due_to_max_attempts = true
      last_login = 100.seconds.ago
      user.time_of_last_login_attempt = last_login
      res = user.can_login?(max_attempts, lock_delay)

      expect(res).to be_falsey
      expect(user.time_of_last_login_attempt).to be == last_login
      expect(user.is_locked_due_to_max_attempts).to be_truthy
      expect(user.number_of_recent_login_attempts).to be == 0
    end

    it 'user was locked but enough time passed since' do
      user.is_locked_due_to_max_attempts = true
      last_login = 400.seconds.ago
      user.time_of_last_login_attempt = last_login
      res = user.can_login?(max_attempts, lock_delay)

      expect(res).to be_truthy
      expect(user.time_of_last_login_attempt).to be > last_login
      expect(user.is_locked_due_to_max_attempts).to be_falsey
      expect(user.number_of_recent_login_attempts).to be == 0
    end

    it 'max attempts reached, but time delay from last attempt was enough' do
      user.number_of_recent_login_attempts = 3
      last_login = 400.seconds.ago
      user.time_of_last_login_attempt = last_login
      res = user.can_login?(max_attempts, lock_delay)

      expect(res).to be_truthy
      expect(user.time_of_last_login_attempt).to be > last_login
      expect(user.is_locked_due_to_max_attempts).to be_falsey
      expect(user.number_of_recent_login_attempts).to be == 0
    end

    it 'max attempts reached and time delay is within the bound' do
      user.number_of_recent_login_attempts = 3
      last_login = 4.seconds.ago
      user.time_of_last_login_attempt = last_login
      res = user.can_login?(max_attempts, lock_delay)

      expect(res).to be_falsey
      expect(user.time_of_last_login_attempt).to be > last_login
      expect(user.is_locked_due_to_max_attempts).to be_truthy
      expect(user.number_of_recent_login_attempts).to be == 0
    end

    it 'max attempts not reached' do
      user.number_of_recent_login_attempts = 2
      last_login = 4.seconds.ago
      user.time_of_last_login_attempt = last_login
      res = user.can_login?(max_attempts, lock_delay)

      expect(res).to be_truthy
      expect(user.time_of_last_login_attempt).to be > last_login
      expect(user.is_locked_due_to_max_attempts).to be_falsey
      expect(user.number_of_recent_login_attempts).to be == 3
    end

    it 'should be locked on the 4th attempt' do
      res = user.can_login?(max_attempts, lock_delay)
      expect(res).to be_truthy
      res = user.can_login?(max_attempts, lock_delay)
      expect(res).to be_truthy
      res = user.can_login?(max_attempts, lock_delay)
      expect(res).to be_truthy
      res = user.can_login?(max_attempts, lock_delay)
      expect(res).to be_falsey
    end
  end

  describe 'filter_authorized_groups' do
    subject { @user }

    before :each do
      FactoryBot.create(:group, id: 1, snapshot_id: 1, external_id: 'g1', name: 'g1', company_id: 1)
      FactoryBot.create(:group, id: 2, snapshot_id: 1, external_id: 'g2', name: 'g2', company_id: 1, parent_group_id:  1)
      FactoryBot.create(:group, id: 3, snapshot_id: 1, external_id: 'g3', name: 'g3', company_id: 1, parent_group_id:  2)
      FactoryBot.create(:group, id: 4, snapshot_id: 1, external_id: 'g4', name: 'g4', company_id: 1, parent_group_id:  2)
      FactoryBot.create(:group, id: 5, snapshot_id: 1, external_id: 'g5', name: 'g5', company_id: 1, parent_group_id:  1)

      @user = User.create!(permissible_group: 'g2', id: 999, company_id: 999, role: :manager, password: '12341324', email: 'r@q.com')
    end

    after :each do
      Rails.cache.clear
      DatabaseCleaner.clean_with(:truncation)
    end

    it 'should restrict only to daugter groups' do
      gids_arr = @user.filter_authorized_groups([1,2,3,4,5]).sort
      expect(gids_arr).to eq([2,3,4])
    end

    it 'should restrict for permissible groups with no hierarchy' do
      @user.update!(permissible_group: 'g5')
      gids_arr = @user.filter_authorized_groups([1,2,3,4,5]).sort
      expect(gids_arr).to eq([5])
    end

    it 'should restrict to correct snapshot' do
      FactoryBot.create(:group, id: 11, snapshot_id: 2, external_id: 'g1', name: 'g1', company_id: 1)
      FactoryBot.create(:group, id: 12, snapshot_id: 2, external_id: 'g2', name: 'g2', company_id: 1, parent_group_id:  11)
      FactoryBot.create(:group, id: 13, snapshot_id: 2, external_id: 'g3', name: 'g3', company_id: 1, parent_group_id:  12)
      FactoryBot.create(:group, id: 14, snapshot_id: 2, external_id: 'g4', name: 'g4', company_id: 1, parent_group_id:  12)
      FactoryBot.create(:group, id: 15, snapshot_id: 2, external_id: 'g5', name: 'g5', company_id: 1, parent_group_id:  11)

      gids_arr = @user.filter_authorized_groups([12,13,14,15]).sort
      expect(gids_arr).to eq([12, 13, 14])
    end

    describe 'authorized_groups' do
      it 'should get all relevant gids from snapshot' do
        FactoryBot.create(:group, id: 11, snapshot_id: 2, external_id: 'g1', name: 'g1', company_id: 1)
        FactoryBot.create(:group, id: 12, snapshot_id: 2, external_id: 'g2', name: 'g2', company_id: 1, parent_group_id:  11)
        FactoryBot.create(:group, id: 13, snapshot_id: 2, external_id: 'g3', name: 'g3', company_id: 1, parent_group_id:  12)

        gids_arr = @user.authorized_groups(1).sort
        expect(gids_arr).to eq([2, 3, 4])

        gids_arr = @user.authorized_groups(2).sort
        expect(gids_arr).to eq([12, 13])
      end
    end
  end
end
