require 'spec_helper'

describe UiLevelConfiguration, type: :model do
  before do
   UiLevelConfiguration.create(company_id: 1, level: 1, display_order: 1, parent_id: 1)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'create ui level configuration ' do
    it ', when valid expected to create new ui level row' do
      before_count = UiLevelConfiguration.count
      valid_row = UiLevelConfiguration.new(company_id: 1, level: 1, display_order: 2, parent_id: 1)
      valid_row.save
      expect(UiLevelConfiguration.count).to eq(before_count + 1)
    end

    it ', when there is allready same level display order and parent, expected to raise error' do
      before_count = UiLevelConfiguration.count
      valid_row = UiLevelConfiguration.new(company_id: 1, level: 1, display_order: 1, parent_id: 1)
      expect {valid_row.save }.to raise_error
    end
  end
end
