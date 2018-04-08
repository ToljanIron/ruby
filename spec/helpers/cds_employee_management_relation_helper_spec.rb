require 'nmatrix'
require 'pp'
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

describe CdsEmployeeManagementRelationHelper, type: :helper do

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  before(:all) do
    Company.find_or_create_by(id: 1, name: "Hevra10")
    Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
    Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
    create_emps('moshe', 'acme.com', 11, {gid: 6})

    ###########################################################
    # 1 is the CEO
    # 2,3 and 4 are managers
    # 11 is not a manger event though he reports to the CEO
    # 5,6,7,8,9 are not managers
    ###########################################################
    managers = [
      [1,2],[1,3],[1,4],[1,11],[2,5],[2,6],[3,7],[4,8],[4,9],[4,10]
    ]
    managers.each do |rel|
      EmployeeManagementRelation.create!(manager_id: rel[0], employee_id: rel[1], relation_type: 'recursive')
    end
  end

  describe 'formal_structure_index' do
    fsi = nil
    before(:all) do
      fsi = formal_structure_index(1)
    end

    it 'should have corret topid' do
      expect(fsi[:topid]).to eq(1)
    end

    it 'should have exact list of peers' do
      expect( fsi[:peers][2].sort ).to eq([3,4])
      expect( fsi[:peers][1].sort ).to eq([])
      expect( fsi[:peers][5] ).to be_nil
    end

    it 'should have correct list of managers' do
      expect( fsi[:managers][9] ).to eq(4)
      expect( fsi[:managers][4] ).to eq(1)
      expect( fsi[:managers][1] ).to be_nil
    end

    it 'should have valid reportees lists' do
      expect( fsi[:reportees][3] ).to eq([7])
    end
  end

  describe 'get_all_managers' do
    it 'should find all managers' do
      res = get_all_managers(1, 6)
      expect( res.sort ).to eq ([1,2,3,4])
    end
  end

  describe 'get_peers' do
    it 'should return nil for the top manager' do
      expect( get_peers(1) ).to be_nil
    end

    it 'should return all peers except for given manager' do
      expect( get_peers(2).sort ).to eq([3,4,11])
    end

    it 'should return nil for regular employee' do
      expect( get_peers(7) ).to be_nil
    end
  end

  describe 'get_top_manager' do
    it 'should find top manger when entering employee' do
      expect( get_top_manager(9) ).to eq(1)
    end

    it 'should find top manger when entering nil' do
      expect( get_top_manager() ).to eq(1)
    end

    it 'should find top manger when entering top manager' do
      expect( get_top_manager(1) ).to eq(1)
    end
  end

end
