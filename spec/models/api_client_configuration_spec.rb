require 'spec_helper'

describe ApiClientConfiguration, type: :model do
  before do
    @api_client_config = ApiClientConfiguration.new(report_if_not_responsive_for: 10)
  end

  subject { @api_client_config }

  it { is_expected.to respond_to(:active_time_start) }
  it { is_expected.to respond_to(:active_time_end) }
  it { is_expected.to respond_to(:disk_space_limit_in_mb) }
  it { is_expected.to respond_to(:wakeup_interval_in_seconds) }
  it { is_expected.to respond_to(:duration_of_old_logs_by_months) }
  it { is_expected.to respond_to(:log_max_size_in_mb) }
  it { is_expected.to respond_to(:active) }
  it { is_expected.to respond_to(:serial) }
  it { is_expected.to be_valid }
  describe 'pack_to_json' do
    params = nil
    before do
      params = {
        active_time_start: '05:00',
        active_time_end: '07:00',
        disk_space_limit_in_mb: 30,
        wakeup_interval_in_seconds: 60,
        duration_of_old_logs_by_months: 20,
        log_max_size_in_mb: 10,
        active: true
      }
      subject.update(params)
    end
    it 'should extract only needed data' do
      res = JSON.parse subject.pack_to_json
      expect(res['active_time_start']).to eq params[:active_time_start]
      expect(res['active_time_end']).to eq params[:active_time_end]
      expect(res['disk_space_limit_in_mb']).to eq params[:disk_space_limit_in_mb]
      expect(res['wakeup_interval_in_seconds']).to eq params[:wakeup_interval_in_seconds]
      expect(res['duration_of_old_logs_by_months']).to eq params[:duration_of_old_logs_by_months]
      expect(res['log_max_size_in_mb']).to eq params[:log_max_size_in_mb]
      expect(res['active']).to eq params[:active]
    end
    it 'should extract only needed data and also return false if active null' do
      params[:active] = nil
      subject.update(params)
      res = JSON.parse subject.pack_to_json
      expect(res['active']).to eq false
    end
  end

  describe 'update_by_json' do
    valid_json = nil
    invalid_json = nil
    before do
      valid_json = {
        serial: 'qweasdzxcqweasdzxc',
        base_url: 'http://localhost:3000/',
        active_time_start: '00:00',
        active_time_end: '22:55',
        log_file_path: 'logs/',
        duration_of_old_logs_by_months: '5',
        log_max_size_in_mb: '3',
        disk_space_limit_in_mb: '21',
        active: 'true',
        token: 'd65028a43e33af193de01e796d576e1b7e6cac318b15151ea7bba3b84ab6',
        wakeup_interval_in_seconds: '50',
        some_other_arg: 'should be ignored'
      }.to_json
      invalid_json = {
        base_url: 'http://localhost:3000/',
        active_time_start: '00:00',
        active_time_end: '22:aa',
        log_file_path: 'logs/',
        duration_of_old_logs_by_months: '5',
        log_max_size_in_mb: '3',
        disk_space_limit_in_mb: '21',
        active: 'true',
        token: 'd65028a43e33af193de01e796d576e1b7e6cac318b15151ea7bba3b84ab6',
        wakeup_interval_in_seconds: '50',
        some_other_arg: 'should be ignored'
      }.to_json
    end
    it 'when json is valid' do
      subject.update_by_json(JSON.parse valid_json)
      subject.reload
      p = JSON.parse valid_json
      expect(subject[:active_time_start]).to eq p['active_time_start']
      expect(subject[:active_time_end]).to eq p['active_time_end']
      expect(subject[:duration_of_old_logs_by_months]).to eq p['duration_of_old_logs_by_months'].to_i
      expect(subject[:log_max_size_in_mb]).to eq p['log_max_size_in_mb'].to_i
      expect(subject[:disk_space_limit_in_mb]).to eq p['disk_space_limit_in_mb'].to_i
      expect(subject[:wakeup_interval_in_seconds]).to eq p['wakeup_interval_in_seconds'].to_i
      expect(subject[:active]).to be true
      expect(subject[:serial]).to eq p['serial']
    end
    it 'when json is invalid' do
      expect { subject.update_by_json(JSON.parse invalid_json) }.to raise_error
    end
  end
end
