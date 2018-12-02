require 'spec_helper.rb'
require 'rake'

describe 'db:update_images_from_s3' do
  before do
    Rake::Task['db:update_images_from_s3'].reenable
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'running the task with non expired images ' do
    before do
      @empl1 = FactoryBot.create(:employee, email: 'gil.rosen@spectory.com', img_url_last_updated: 2.hours.ago)
      @empl2 = FactoryBot.create(:employee, email: 'someone.rosen@spectory.com', img_url_last_updated: 3.hours.ago)
      @empl3 = FactoryBot.create(:employee, email: 'johndoe@spectory.com', img_url_last_updated: 4.hours.ago)
      @last_updated1 = @empl1.img_url_last_updated
      @last_updated2 = @empl2.img_url_last_updated
      @last_updated3 = @empl3.img_url_last_updated
      ENV['COMPANY_ID'] = '1'
    end
    it 'should not  update the imgurl field' do
      Rake::Task['db:update_images_from_s3'].execute
      expect(Employee.find_by(email: @empl1.email).img_url_last_updated).not_to eq(@last_updated1)
      expect(Employee.find_by(email: @empl2.email).img_url_last_updated).not_to eq(@last_updated2)
      expect(Employee.find_by(email: @empl3.email).img_url_last_updated).not_to eq(@last_updated3)
    end
  end

  describe 'running the task with  expired images ' do
    @empl4 = {}
    before do
      @empl4 = FactoryBot.create(:employee, email: 'gil.rosen2@spectory.com', img_url_last_updated: 28.hours.ago)
      @empl5 = FactoryBot.create(:employee, email: 'someone.rosen@spectory.com', img_url_last_updated: 35.hours.ago)
      @empl6 = FactoryBot.create(:employee, email: 'johndoe@spectory.com', img_url_last_updated: 42.hours.ago)
      @last_updated4 = @empl4.img_url_last_updated
      @last_updated5 = @empl5.img_url_last_updated
      @last_updated6 = @empl6.img_url_last_updated
      ENV['COMPANY_ID'] = '1'
    end
    it 'should  update the imgurl field' do
      Rake::Task['db:update_images_from_s3'].execute
      expect(Employee.find_by(email: @empl4.email).img_url_last_updated).not_to eq(@last_updated4)
      expect(Employee.find_by(email: @empl5.email).img_url_last_updated).not_to eq(@last_updated5)
      expect(Employee.find_by(email: @empl6.email).img_url_last_updated).not_to eq(@last_updated6)
    end
  end
end
