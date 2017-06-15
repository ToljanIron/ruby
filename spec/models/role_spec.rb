require 'spec_helper'
RSpec.describe Role, type:  :model do
  before do
    comp = Company.create(name: 'Comp')
    color = Color.create(rgb: 'Blue')
    @r = Role.create(company_id: comp.id, name: 'Developer', color_id: color.id)
  end

  it 'Should be able to use .company and the .color notations' do
    expect(@r.company.name).to eq('Comp')
    expect(@r.color.rgb).to eq('Blue')
  end
end
