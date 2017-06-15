require 'spec_helper'

describe Group, type: :model do
  def create_groups
    Company.create!(id: 0, name: 'comp')
    @parent_group = FactoryGirl.create(:group, name: 'parent', company_id: 0)
    @child_group =  FactoryGirl.create(:group, name: 'child', company_id: 0, parent_group_id: @parent_group.id)
    @child_group_employees_ids = []
    @parent_group_employees_ids = []
    @total_employess = rand(100) + 2
  end

  def create_employees
    (1..@total_employess).each do
      e = FactoryGirl.create(:employee)
      if rand(100) > 50
        e.group = @parent_group
        @parent_group_employees_ids.push e.id
      else
        e.group = @child_group
        @child_group_employees_ids.push e.id
      end
      e.save!
    end
  end

  subject { @group }

  before do
    @group = Group.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  it { is_expected.to respond_to(:name) }
  it { is_expected.to respond_to(:company_id) }
  it { is_expected.to respond_to(:parent_group_id) }

  it ', Group.by_company_id should return all groups of company' do
    n = rand(1..100)
    company_id = rand(1..5)
    counter = 0
    (1..n).each do |i|
      id = rand(1..5)
      FactoryGirl.create(:group, name: "name_#{i}", company_id: id)
      counter += 1 if company_id == id
    end
    expect((Group.by_company_id company_id).count).to eq(counter)
  end

  describe ', with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end

  describe ', with valid data should be valid' do
    it do
      subject[:name] = 'some name'
      subject[:company_id] = 0
      is_expected.to be_valid
    end
  end

  describe ', model functionality' do

    before(:each) do
      create_groups
      create_employees
    end

    after do
      FactoryGirl.reload
    end

    it ', parent group contain all employees' do
      res = @parent_group.extract_employees.count
      expect(res).to eq(@total_employess)
    end
    it ', parent_group should contain the set of all employees' do
      res = @parent_group.extract_employees | @child_group.extract_employees
      expected = @parent_group_employees_ids | @child_group_employees_ids
      expect(res.sort).to eq(expected.sort)
    end
    it ', child_group should be a subset of parent_group' do
      res = @child_group.extract_employees
      expect(res.sort).to eq(@child_group_employees_ids.sort)
    end

    describe ', pack_to_json' do

      it ', parent_group should return hashed summary' do
        res = @parent_group.pack_to_json
        expect(res[:id]).to eq(@parent_group.id)
        expect(res[:name]).to eq(@parent_group.name)
        expected = @parent_group_employees_ids | @child_group_employees_ids
        expect(res[:employees_ids].sort).to eq(expected.sort)
        expect(res[:child_groups]).to eq([@child_group.id])
        expect(res[:parent]).to be_nil
      end

      it ', child_group should return hashed summary' do
        res = @child_group.pack_to_json
        expect(res[:id]).to eq(@child_group.id)
        expect(res[:name]).to eq(@child_group.name)
        expect(res[:employees_ids].sort).to eq(@child_group_employees_ids.sort)
        expect(res[:child_groups]).to eq([])
        expect(res[:parent]).to eq(@parent_group.id)
      end

      it ', In investigation state a group name should be preceeded with the group id' do
        CompanyConfigurationTable.create!(key: "INVESTIGATION_MODE", value: 'true', comp_id: -1)
        res = @child_group.pack_to_json
        expect(res[:id]).to eq(@child_group.id)
        augmented_group_name = "#{@child_group.id}-#{@child_group.name}"
        expect(res[:name]).to eq(augmented_group_name)
      end
    end
  end

  describe 'sibling_groups' do
    it 'should return groups under same parent' do
      FactoryGirl.create_list(:group, 4)
      Group.first(2).each { |g| g.update(parent_group_id: 100) }
      Group.last(2).each { |g| g.update(parent_group_id: 1) }
      expect(Group.first.sibling_groups).to eq([Group.second])
    end
  end

end
