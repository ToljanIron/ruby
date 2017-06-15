require 'spec_helper'

describe ArchivedApiClientTask, type: :model do
  before do
    @scheduled_task = ArchivedApiClientTask.new
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @scheduled_task }

  it { is_expected.to respond_to(:api_client_task_definition_id) }
  it { is_expected.to respond_to(:status) }
  it { is_expected.to respond_to(:params) }
  it { is_expected.to respond_to(:jobs_queue_id) }
  it { is_expected.to respond_to(:api_client_id) }
  it { is_expected.not_to be_valid }
end
