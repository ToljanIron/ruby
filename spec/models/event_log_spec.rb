require 'spec_helper'
# require ''

describe EventLog, type: :model do
  before do
    @event_log = EventLog.new
    EventType.create(name: 'GENERAL_EVENT')
    EventType.create(name: 'JOB_STARTED')
    EventType.create(name: 'JOB_DONE')
    EventType.create(name: 'JOB_KILLED_ERR_DID_NOT_RUN')
    EventType.create(name: 'JOB_KILLED_ERR_DID_NOT_FINISH')
    EventType.create(name: 'JOB_ARCHIVED')
    EventType.create(name: 'JOB_FAIL')
    EventType.create(name: 'JOB_ARCHIVED')
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @event_log }

  it { is_expected.to respond_to(:message) }
  it { is_expected.to respond_to(:job_id) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe 'crate a new log with new format' do
    it do
      length_before = EventLog.all.length
      hash = {}
      hash.store(:event_type_name, 'JOB_STARTED')
      hash.store(:message, 'test...')
      EventLog.log_event(hash)
      expect(length_before).to eq(EventLog.all.length - 1)
    end
  end

  describe 'create a log that job pass' do
    it do
      length_before = EventLog.all.length
      EventLog.log_event(event_type_name: 'JOB_DONE', job_id: 'JOB_DONE', message: 'done')
      expect(length_before).to eq(EventLog.all.length - 1)
    end
  end

  describe 'create a log that hash no event type id value' do
    it do
      length_before = EventLog.all.length
      EventLog.log_event(message: 'done')
      expect(length_before).to eq(EventLog.all.length - 1)
      expect(EventLog.all.first.event_type_id).to eq(0)
    end
  end
end
