require 'spec_helper'

include SessionsHelper

describe UtilsController, type: :controller do

  before do
    log_in_with_dummy_user_with_role(1)

    Color.create(id: 1, rgb: '#3bc1ed')
    Color.create(id: 2, rgb: '#5fb3de')
    (3..12).each { |i| Color.create(id: i, rgb: "#ababa#{i}")}
    Rank.create(id: 1, name: '1', color_id: 1)
    Rank.create(id: 2, name: '2', color_id: 2)
    Role.create(id: 1, company_id: 1, name: 'Developer', color_id: 1)
    Role.create(id: 2, company_id: 1, name: 'Tester', color_id: 2)

    Employee.create!(email: 'e1@mail.com', company_id: 1, first_name: 'E', last_name: 'e', color_id: 1, external_id: 22)
    Employee.create!(email: 'e2@mail.com', company_id: 1, first_name: 'E', last_name: 'e', color_id: 2, external_id: 44)

    Group.create!(company_id: 1, name: 'group1', color_id: 2)
    Group.create!(company_id: 1, name: 'group2', color_id: 1)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it ', should be signed in' do
    expect(current_user).to eq(@user)
  end

  describe ', check colors structure' do
    it 'should ' do
      res = get :list_colors
      res = JSON.parse res.body
      expect(res['g_id']['2']).to eq('#3bc1ed')
      expect(res['manager_id']['2']).to eq('#5fb3de')
      expect(res['attributes']['Developer']).to eq('#3bc1ed')
    end
  end

  describe '#create_and_download_report_xls' do
    before do
      allow_any_instance_of(UtilsController).to receive(:write_report_to_sheet).and_return(true)
      allow_any_instance_of(UtilsController).to receive(:create_file).and_return(WriteExcel.new('/tmp/filename'))
      allow_any_instance_of(WriteExcel).to receive(:add_worksheet).and_return(true)
      allow_any_instance_of(WriteExcel).to receive(:close).and_return(true)
      @params = { employee_data: [{ title: 'flag1', employee_ids: [1, 2, 3] }], group_id: 1, pin_id: -1 }
    end

    after do
      File.delete('/tmp/filename') if File.exist?('/tmp/filename')
      File.delete(Rails.root.join('tmp', 'filename.xls')) if File.exist?(Rails.root.join('tmp', 'filename.xls'))
    end

    it 'should create xls' do
      expect_any_instance_of(UtilsController).to receive(:create_file)
      post :init_report_xls, @params
      post :create_and_download_report_xls, @params
    end

    it 'should create worksheet with correct title' do
      expect_any_instance_of(WriteExcel).to receive(:add_worksheet).with(@params[:employee_data][0][:title])
      post :init_report_xls, @params
      post :create_and_download_report_xls, @params
    end

    it 'should call write_report_to_sheet with correct params' do
      expect_any_instance_of(UtilsController).to receive(:write_report_to_sheet)
      post :init_report_xls, @params
      post :create_and_download_report_xls, @params
    end

    it 'should render JSON' do
      post :init_report_xls, @params
      post :create_and_download_report_xls, @params
      expect(response.body).to_not be nil
    end
  end

  describe '#export_xls' do
    it 'should send file' do
      File.open(Rails.root.join('tmp', 'filename.xls'), 'w+') { |file| file.write(' ') }
      get :export_xls, filename: 'filename.xls'
      expect(response['Content-Disposition']).to eq "attachment; filename=\"filename.xls\""
      expect(response['Content-Type']).to eq 'application/vnd.ms-excel'
    end
  end

  describe 'fetch_group_individual_state' do
    it 'should return deafult value if not exist a value seeting' do
      res = get :fetch_group_individual_state
      res = JSON.parse res.body
      expect(res['state']).to be false
    end

    it 'should return true if the group_individual_state  value is true' do
      UserConfiguration.create!(key: 'bottom_up_view', value: 'true', user_id: 1)
      res = get :fetch_group_individual_state
      res = JSON.parse res.body
      expect(res['state']).to eq 'true'
    end
  end
  describe 'save_group_individual_state' do
    it 'should save value true' do
      res = get :save_group_individual_state, state: 'true'
      res = JSON.parse res.body
      expect(UserConfiguration.count).to be 1
      expect(UserConfiguration.first.value).to eq true.to_s
      expect(res['success']).to be true
      expect(res['state']).to eq 'true'
    end
    it 'should save value false' do
      res = post :save_group_individual_state, state: 'false'
      res = JSON.parse res.body
      expect(UserConfiguration.count).to be 1
      expect(UserConfiguration.first.value).to eq false.to_s
      expect(res['success']).to be true
      expect(res['state']).to eq 'false'
    end
  end
end
