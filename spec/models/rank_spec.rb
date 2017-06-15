require 'spec_helper'

RSpec.describe Rank, type: :model do
  before do
    color = Color.create(rgb: 'Red')
    @r = Rank.create(id: 1, name: '1', color_id: color.id)
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'Should be able to use the .color notations' do
    expect(@r.color.rgb).to eq('Red')
  end
end
