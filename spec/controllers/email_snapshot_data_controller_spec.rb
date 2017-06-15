require 'spec_helper'
require './spec/spec_factory'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe EmailSnapshotDataController, type: :controller do
  before do
    # Login with hr user
    log_in_with_dummy_user_with_role(1)
  end
  describe 'Test results with ' do
    before do
      Metric.create(name: 'Collaboration', metric_type: 'analyze', index: 0)
      Company.create(name: 'company1')
      Snapshot.create(name: 's1', company_id: 1, snapshot_type: 1)
      Snapshot.create(name: 's2', company_id: 1, snapshot_type: 1)
      last_snapshot = Snapshot.create(name: 's3', company_id: 1, snapshot_type: 1)
      last_snapshot.update(timestamp: last_snapshot[:created_at])

      @g1 = FactoryGirl.create(:group, name: 'group_1', company_id: 1)
      @g2 = FactoryGirl.create(:group, name: 'group_2', company_id: 1)
      @g3 = FactoryGirl.create(:group, name: 'group_3', company_id: 1)

      email_1 = 'p1@email.com'
      email_2 = 'p2@email.com'
      email_3 = 'p3@email.com'
      email_4 = 'p4@email.com'
      email_5 = 'p5@email.com'

      @emp_1 = FactoryGirl.create(:employee, email: email_1, group_id: 1)
      @emp_2 = FactoryGirl.create(:employee, email: email_2, group_id: 1)
      @emp_3 = FactoryGirl.create(:employee, email: email_3, group_id: 1)
      @emp_4 = FactoryGirl.create(:employee, email: email_4, group_id: 1)
      @emp_5 = FactoryGirl.create(:employee, email: email_5)

      create_node_entry(@emp_2, @emp_3, 3, 5, false)
      create_node_entry(@emp_4, @emp_1, 3, 10, true)
      create_node_entry(@emp_1, @emp_3, 3, 4, false)
      create_node_entry(@emp_4, @emp_2, 3, 31, false)
      create_node_entry(@emp_5, @emp_4, 3, 13, false)
      create_node_entry(@emp_1, @emp_2, 3, 1, false)

      @pin = Pin.create(company_id: 1, name: 'testpin', definition: 'some def')
      EmployeesPin.create(pin_id: @pin.id, employee_id: @emp_1.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: @emp_2.id)
      EmployeesPin.create(pin_id: @pin.id, employee_id: @emp_3.id)
      Rake::Task['db:precalculate_metric_scores'].invoke(1)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
      Rake::Task['db:precalculate_metric_scores'].reenable
    end
  end
end
