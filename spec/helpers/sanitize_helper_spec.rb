require 'spec_helper'
require './spec/spec_factory'

describe SanitizeHelper, type: :helper do
  describe 'sanitize_gids' do
    it 'should pass array of ints' do
      expect( sanitize_gids([1,2,3]) ).to eq([1,2,3])
    end

    it 'should pass array with numeric string' do
      expect( sanitize_gids([1,'1']) ).to eq([1, '1'])
    end

    it 'should fail non-array' do
      expect{ sanitize_gids(boolean) }.to raise_error
    end

    it 'should fail with none numeric string' do
      expect( sanitize_gids([1,2,3]) ).to eq([1,2,3])
    end

    it 'should fail array with object' do
      expect{ sanitize_gids([{},1]) }.to raise_error
    end

    it 'should return nil if is nil' do
      expect( sanitize_gids(nil) ).to eq(nil)
    end

    it 'should return [] if is empty' do
      expect( sanitize_gids([]) ).to eq([])
    end

    it 'should accept a string of numbers and commas' do
      s = "1,2,3,4"
      expect( sanitize_gids(s) ).to eq(s)
    end

    it 'should not accept a string other than numbers and commas' do
      s = "1,2,3, 4"
      expect{ sanitize_gids(s) }.to raise_error
    end
  end

  describe 'sanitize_alphanumeric_with_slash' do
    it 'should return same string' do
      s = 'abcd123/'
      expect(sanitize_alphanumeric_with_slash(s)).to eq(s)
    end

    it 'should not accept space' do
      s = 'abc d123/'
      expect{ sanitize_alphanumeric_with_slash(s) }.to raise_error
    end

    it 'should return nil' do
      expect(sanitize_alphanumeric_with_slash(nil)).to eq(nil)
    end

    it 'should not accept space' do
      expect( sanitize_alphanumeric_with_slash('') ).to eq('')
    end
  end

  describe 'sanitize_id' do
    it 'should retrun same number' do
      expect( sanitize_id(12)).to eq(12)
    end

    it 'should retrun same string if string is a number' do
      expect( sanitize_id('12') ).to eq('12')
    end

    it 'should retrun nil' do
      expect( sanitize_id(nil) ).to be_nil
    end

    it 'should retrun nil if is empty string' do
      expect( sanitize_id('') ).to be_nil
    end

    it 'should not accpet a string that is not a number' do
      expect{ sanitize_id('s') }.to raise_error
    end
  end

  describe 'sanitze_boolean' do
    it 'should retrun same input' do
      expect( sanitze_boolean(true)).to eq(true)
      expect( sanitze_boolean('true')).to eq('true')
      expect( sanitze_boolean('True')).to eq('True')
      expect( sanitze_boolean(false)).to eq(false)
      expect( sanitze_boolean('false')).to eq('false')
      expect( sanitze_boolean('False')).to eq('False')
    end

    it 'should retrun nil' do
      expect( sanitze_boolean(nil) ).to be_nil
    end

    it 'should retrun nil if is empty string' do
      expect( sanitze_boolean('') ).to be_nil
    end

    it 'should not accpet a string that is not a boolean' do
      expect{ sanitze_boolean('s') }.to raise_error
    end
  end

  describe 'sanitize_number' do
    it 'should retrun same input' do
      expect( sanitize_number(3)).to eq(3)
      expect( sanitize_number(-3)).to eq(-3)
      expect( sanitize_number(3.1)).to eq(3.1)
      expect( sanitize_number('3')).to eq('3')
    end

    it 'should retrun nil' do
      expect( sanitize_number(nil) ).to be_nil
    end

    it 'should retrun nil if is empty string' do
      expect( sanitize_number('') ).to be_nil
    end

    it 'should not accpet a string that is not a number' do
      expect{ sanitize_number('s') }.to raise_error
    end

    it 'should not accpet a space' do
      expect{ sanitize_number(' ') }.to raise_error
    end
  end

  describe 'sanitize_alphanumeric_with_space' do
    it 'should return same string' do
      s = 'abc d12 3/'
      expect(sanitize_alphanumeric_with_space(s)).to eq(s)
    end

    it 'should return nil' do
      expect(sanitize_alphanumeric_with_space(nil)).to eq(nil)
    end
  end
end
