require 'spec_helper'

RSpec.describe Seniority, type: :model do
  before do
    color = Color.create(rgb: 'Red')
    @r = Seniority.create(id: 1, name: '1', color_id: color.id)
  end

  it 'Should be able to use the .color notations' do
    expect(@r.color.rgb).to eq('Red')
  end
end
