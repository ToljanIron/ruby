require 'spec_helper'

RSpec.describe GaugeConfiguration, type: :model do
  before do
    @gc = GaugeConfiguration.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'populate' do
    it 'populates with new values' do
      @gc.populate(create_gauge_params,22)
      expect(@gc.maximum_value).to eq(20)
      expect(@gc.company_id).to eq(22)
    end
  end

  describe 'configuration_is_empty?' do
    it 'return false if not empty' do
      @gc.populate(create_gauge_params,22)
      expect(@gc.configuration_is_empty?).to be_falsey
    end

    it 'return true if empty' do
      @gc.populate(create_empty_gauge_params,22)
      expect(@gc.configuration_is_empty?).to be_truthy
    end
  end
end

def create_gauge_params
  return {
    min_range: 0,
    min_range_wanted: 60,
    max_range: 20,
    max_range_wanted: 100
  }
end

def create_empty_gauge_params
  return {
    min_range: -1,
    min_range_wanted: -1,
    max_range: -1,
    max_range_wanted: -1
  }
end
