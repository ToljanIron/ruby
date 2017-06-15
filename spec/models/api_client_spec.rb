require 'spec_helper'

describe ApiClient, type: :model do
  before do
    @client = ApiClient.create_new_client('New Client')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @client }

  it { is_expected.to respond_to(:client_name) }
  it { is_expected.to respond_to(:token) }
  it { is_expected.to respond_to(:expires_on) }
  it { is_expected.to respond_to(:last_contact) }
  it { is_expected.to be_valid }

  describe 'should authenticate client' do
    it 'should accept client' do
      res = ApiClient.authenticate_client(subject.token)
      expect(res).not_to be_nil
    end
    it 'should deny client' do
      res = ApiClient.authenticate_client(SecureRandom.hex(30))
      expect(res).to be_nil
    end
  end

  describe 'update_last_contact' do
    it 'should set last_contact to now' do
      subject.last_contact = 1.hour.ago
      subject.update_last_contact
      res = subject.last_contact > 1.minute.ago
      expect(res).to be true
    end
  end

  describe 'schedule_config_file_update' do
    before do
      ApiClientTaskDefinition.create(
        name: 'update_config',
        script_path: 'update_config.rb'
      )
      config = FactoryGirl.create(:api_client_configuration)
      subject.update(api_client_configuration_id: config.id)
    end

    xit 'should create ScheduledApiClientTask' do
      expect { subject.schedule_config_file_update }.to change { ScheduledApiClientTask.count }.by(1)
    end

    xit 'new ScheduledApiClientTask should be with high priority' do
      scheduled_task = subject.schedule_config_file_update
      expect(scheduled_task.priority?).to be true
    end
  end

  describe 'needs_config_sync' do
    config = nil
    before do
      config = FactoryGirl.create(:api_client_configuration)
      subject.update(api_client_configuration_id: config.id)
    end
    it 'when serials match' do
      expect(subject.needs_config_sync? config.serial).to be false
    end
    it 'when serials does not match' do
      expect(subject.needs_config_sync? 'other random serial').to be true
    end
  end
end
