require 'spec_helper'

RSpec.describe EventType, type: :model do
  before do
    @event_type = EventType.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @event_type }

  it { is_expected.to respond_to(:name) }

  describe 'create event type that pass' do
    it 'creates the event' do
      expect { EventType.create_job_event('JOB_STARTED') }.to change { EventType.count }.by 1
    end
  end

  describe 'create event type that fails' do
    it 'creates the event' do
      expect { EventType.create_job_event('JOB_FAILED') }.to change { EventType.count }.by 1
    end
  end

  describe 'create event that does not exist' do
    it 'creates the event' do
      expect { EventType.create_job_event('JOB_NEW') }.to change { EventType.count }.by 1
    end
  end

  describe 'create event with a string and not with symbol' do
    it 'creates the event' do
      expect { EventType.create_job_event('new_event_string') }.to change { EventType.count }.by 1
    end
  end
end
