require 'spec_helper'

describe ApiClientConfiguration, type: :model do
  before do
    @male_img = StackOfImage.create(img_name: 'male_img', gender: StackOfImage::MALE)
    @female_img = StackOfImage.create(img_name: 'female_img', gender: StackOfImage::FEMALE)
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'random_image' do
    emp = nil
    before do
      emp = FactoryGirl.create(:employee)
    end
    it 'when employee is male' do
      emp.male!
      res = StackOfImage.random_image emp
      expect(res).to eq @male_img.img_name
    end
    it 'when employee is female' do
      emp.female!
      res = StackOfImage.random_image emp
      expect(res).to eq @female_img.img_name
    end
  end
end
