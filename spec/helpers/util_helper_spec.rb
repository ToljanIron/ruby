require 'spec_helper'

describe UtilHelper, type: :helper do
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

    describe 'lev' do
      it 'should work' do
        puts "aa - ab - #{UtilHelper.lev('aa', 'ab')}"
        puts "ab - aa - #{UtilHelper.lev('ab', 'aa')}"
        puts "aa - aa - #{UtilHelper.lev('aa', 'aa')}"
        puts "aa - bb - #{UtilHelper.lev('aa', 'bb')}"
        puts "aa - Aa - #{UtilHelper.lev('aa', 'Aa')}"
      end
    end
  end
end
