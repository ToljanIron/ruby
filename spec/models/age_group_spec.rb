require 'spec_helper'

RSpec.describe AgeGroup, type: :model do
  before do
    color = Color.create(rgb: 'Red')
    @r = AgeGroup.create(id: 1, name: '1', color_id: color.id)
  end

  it 'Should be able to use the .color notations' do
    expect(@r.color.rgb).to eq('Red')
  end
end
