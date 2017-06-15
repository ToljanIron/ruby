require 'spec_helper'
require './spec/spec_factory'
describe ApplicationHelper, type: :helper do
  before do
    EventType.create!(name: 'ERROR')
    @user = User.new(first_name: 'name', email: 'user@company.com', password: 'qwe123', password_confirmation: 'qwe123', tmp_password: '$2a$10$4Nr/8.o.BeDLbR.c2MF.e.AwNokjWyqcdYqT7WUYryi9jWRRb8t2O', tmp_password_expiry: DateTime.now + 1.week)
    @user_tmp_password_expired = User.new(first_name: 'name_token', email: 'user_token@company.com', password: 'qwe123', password_confirmation: 'qwe123', tmp_password_expiry: DateTime.now - 1.week)
    @invalid_user = User.new(first_name: 'name2', email: 'user2@company.com', password: 'qwe123', password_confirmation: 'qwe123')
    @user.save!
    @user_tmp_password_expired.save!
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  example_response = "{\"22\":{\"question_id\":22,\"question\":\"Who do you know?\",\"responding_employee_id\":0,\"responses\":[{\"employee_id\":0,\"response\":true},{\"employee_id\":1,\"response\":true},{\"employee_id\":2,\"response\":true},{\"employee_id\":3,\"response\":false},{\"employee_id\":4,\"response\":false},{\"employee_id\":5,\"response\":false},{\"employee_id\":6,\"response\":false},{\"employee_id\":7,\"response\":true},{\"employee_id\":8,\"response\":false}]},\"24\":{\"question_id\":24,\"question\":\"Who do you like?\",\"responding_employee_id\":0,\"responses\":[{\"employee_id\":4,\"response\":null},{\"employee_id\":8,\"response\":null},{\"employee_id\":2,\"response\":null},{\"employee_id\":1,\"response\":null}]}}"
  describe ', parse_response_by_question_id' do
    it 'should return answering emplyee id ' do
      res = parse_response_by_question_id(example_response, '22')
      expect(res[:id]).to eq(0)
      res = parse_response_by_question_id(example_response, '24')
      expect(res[:id]).to eq(0)
    end
    it 'should return ids where response==true ' do
      res = parse_response_by_question_id(example_response, '22')
      expect(res[:friends]).to eq([0, 1, 2, 7])
      res = parse_response_by_question_id(example_response, '24')
      expect(res[:friends]).to eq([])
    end
  end

  describe 'authenticate_by_email_and_temporary_password ' do
    it 'should verify the user by tmp password ' do
      res = authenticate_by_email_and_temporary_password(@user.email, '123123')
      @user.reload
      expect(res).to eq(true)
    end
    it 'should fail - tmp password is expired' do
      res = authenticate_by_email_and_temporary_password(@user_tmp_password_expired.email, '123123')
      @user.reload
      expect(res).to eq(false)
    end
  end
end
