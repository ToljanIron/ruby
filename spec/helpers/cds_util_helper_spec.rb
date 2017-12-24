require 'spec_helper'

describe CdsUtilHelper, type: :helper do
  ########################### Stat Functions ###########################
  describe 'Stat functions' do
    describe 'array_mean' do
      it 'Should throw exception there is no argument' do
        expect {array_mean}.to raise_error
      end

      it 'Should throw exception if argument is nil' do
        expect {array_mean}.to raise_error
      end

      it 'Should throw exception if argument is not array' do
        expect {array_mean(1)}.to raise_error
      end

      it 'Should throw exception if argument is emptyarray' do
        expect {array_mean([])}.to raise_error
      end

      it 'Should not throw exception if argument is non emtpy array' do
        expect {array_mean([1])}.not_to raise_error
      end

      it 'Should be able to calclulate mean value' do
        expect( array_mean([1,2,3,4,5])).to eq(3.0)
      end

      it 'Should throw exception if one of the value is none numeric' do
        expect{ array_mean([1, 'A', 3]) }.to raise_error
      end
    end

    describe 'array_sd' do
      it 'Should throw exception there is no argument' do
        expect {array_sd}.to raise_error
      end

      it 'Should throw exception if argument is nil' do
        expect {array_sd}.to raise_error
      end

      it 'Should throw exception if argument is not array' do
        expect {array_sd(1)}.to raise_error
      end

      it 'Should throw exception if argument is emptyarray' do
        expect {array_sd([])}.to raise_error
      end

      it 'Should throw exception if argument one element array' do
        expect {array_sd([1])}.to raise_error
      end

      it 'Should be able to calclulate std value' do
        expect( array_sd([1,2,3,4,5])).to eq(1.581)
      end

      it 'Should throw exception if one of the value is none numeric' do
        expect{ array_sd([1, 'A', 3]) }.to raise_error
      end
    end
  end

  describe 'create_index' do
    before :all do
      Role.create!(id: 111, company_id: 1, name: 'role1', color_id: 11)
      Role.create!(id: 222, company_id: 1, name: 'role2', color_id: 12)
      Role.create!(id: 333, company_id: 1, name: 'role3', color_id: 13)
    end

    after :each do
      Rails.cache.clear
    end

    it 'should have same number of entries as table if no condition given' do
      res = create_index(Role)
      expect(res.length).to eq(3)
    end

    it 'should have only 2 entries with this condition' do
      res = create_index(Role, 'id', 'id < 300')
      expect(res.length).to eq(2)
    end

    it 'should have string key' do
      res = create_index(Role, 'name', 'id < 300')
      expect(res['role2']).to include({"color_id" => 12})
    end
  end
end
