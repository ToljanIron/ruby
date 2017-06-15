require 'spec_helper.rb'
require 'rake'

describe 'db:simulate_employees_friendships' do
  before do
    FactoryGirl.create_list(:employee, 10)
    Rake::Task['db:simulate_employees_friendships'].execute
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  # describe 'runnig the task with valid ' do
  #   it ',should create (Employee.count^2 - Employee.count) Friendships' do
  #     c = Employee.count
  #     expect(Friendship.count).to eq(c * c - c)
  #   end
  # end
end
