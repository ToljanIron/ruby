require 'spec_helper'
require 'rake'

describe 'keep alive task' do
  def create_scheduled_tasks
    @ac = ApiClient.create_new_client('test_comp')
    @acc = ApiClientConfiguration.create(
      active_time_start: '02:22',
      active_time_end: '02:55',
      disk_space_limit_in_mb: 21,
      wakeup_interval_in_seconds: 100,
      report_if_not_responsive_for: 5
    )
    @ac.update(api_client_configuration_id: @acc.id)
  end

  before(:each) do
    Rake::Task['db:seed:event_types'].reenable
    Rake::Task['db:seed:event_types'].invoke
    create_scheduled_tasks
  end

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'when task has expired' do
    it 'should not write to the log' do
      @ac.update_attribute(:last_contact, Time.now - 2.minutes)
      Rake::Task['db:keep_alive_task'].execute
      expect(EventLog.any?).to be false
    end

    it 'should write to the log' do
      @ac.update_attribute(:last_contact, Time.now - 10.minutes)
      Rake::Task['db:keep_alive_task'].execute
      expect(EventLog.any?).to be true
    end
  end
end
