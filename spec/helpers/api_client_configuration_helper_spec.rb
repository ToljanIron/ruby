require 'spec_helper'
describe ApiClientConfigurationHelper, type: :helper do
  describe 'valid_active_time_start?' do
    valid_examples = %w( 00:00 01:43 22:59)
    invalid_examples = %w( 0 1:43 1:1 24:00 11:68)
    before do
    end
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_active_time_start? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_active_time_start? e).to be false
      end
    end
  end

  describe 'valid_active_time_end?' do
    valid_examples = %w( 00:01 01:03 21:19)
    invalid_examples = %w( -10 3 11:1 11:24:00 222:68)
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_active_time_end? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_active_time_end? e).to be false
      end
    end
  end

  describe 'valid_log_max_size_in_mb?' do
    valid_examples = %w( 1 11 22 33 6545 0005)
    invalid_examples = %w( -10 0 000 aaa eee)
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_log_max_size_in_mb? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_log_max_size_in_mb? e).to be false
      end
    end
  end

  describe 'valid_disk_space_limit_in_mb?' do
    valid_examples = %w( 500 600 7000)
    invalid_examples = %w( ``` 2111sa aa33re )
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_disk_space_limit_in_mb? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_disk_space_limit_in_mb? e).to be false
      end
    end
  end

  describe 'valid_duration_of_old_logs_by_months?' do
    valid_examples = %w( 99 90 )
    invalid_examples = %w( 9*9 11_000 )
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_duration_of_old_logs_by_months? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_duration_of_old_logs_by_months? e).to be false
      end
    end
  end

  describe 'valid_active?' do
    valid_examples = %w( true True TRUE FALSE false False )
    invalid_examples = %w( 0 1 aaa ddd falsess trueS )
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_active? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_active? e).to be false
      end
    end
  end

  describe 'valid_serial?' do
    valid_examples = %w( any kind of string)
    invalid_examples = [1, nil, {}]
    it 'when valid' do
      valid_examples.each do |e|
        expect(valid_serial? e).to be true
      end
    end
    it 'when invalid' do
      invalid_examples.each do |e|
        expect(valid_serial? e).to be false
      end
    end
  end
end
