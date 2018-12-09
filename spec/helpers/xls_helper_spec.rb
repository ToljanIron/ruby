require 'spec_helper'
require './spec/spec_factory'
include CompanyWithMetricsFactory

describe XlsHelper, type: :helper, write_file: true do
  let(:employee) do
    FactoryBot.create(:group_employee,
                       first_name: 'First',
                       last_name: 'Last',
                       img_url: 'http://www.spectory.com/assets/spectory_landing_logo-1385b018b88b241eb8fa4c73864ffb47.png',
                       rank_id: 12,
                       job_title_id: 1,
                       gender: 1,
                       office_id: 1)
  end
  let(:employee2) do
    FactoryBot.create(:group_employee,
                       first_name: 'Second',
                       last_name: 'Last',
                       img_url: 'http://www.spectory.com/assets/spectory_landing_logo-1385b018b88b241eb8fa4c73864ffb47.png',
                       rank_id: 12,
                       job_title_id: 1,
                       gender: 1,
                       office_id: 1)
  end
  let(:group1) { FactoryBot.create(:group, id: 1, name: 'group1', parent_group_id: 2) }
  let(:parent_group) { FactoryBot.create(:group, id: 2, name: 'div') }
  let(:group2) { FactoryBot.create(:group, id: 3, name: 'subgroup', parent_group_id: 1) }
  let(:office1) { FactoryBot.create(:office, id: 1, name: 'tlv') }

  before do
    @file_name = "emp_report-#{Time.now.to_f.to_s[11, 15]}.xls"
    @metric_row = MetricScore.create(company_id: employee[:company_id], snapshot_id: 1, group_id: 1, employee_id: employee[:id], metric_id: 1, score: 9.99)
    @snapshot = Snapshot.create(company_id: 1, name: 'snapshot1')
    @pin = Pin.create(company_id: 1, name: 'pin1')
    group1
    office1
    parent_group
    @jt = JobTitle.create(id: 1, name: 'ceo')
    CompanyWithMetricsFactory.create_metrics
    @workbook = create_file(@file_name)
    allow(@workbook).to receive(:add_format).and_return(Writeexcel::Format.new)
    allow_any_instance_of(Writeexcel::Format).to receive(:set_align).and_return(true)
    File.delete("#{Rails.root}/tmp/#{@file_name}") if File.exist?("#{Rails.root}/tmp/#{@file_name}")
    @worksheet = @workbook.add_worksheet('Worksheet')
    @center = @workbook.add_format
    @red = @workbook.add_format
    @green = @workbook.add_format
    [@center, @red, @green].each { |format| format.set_align('center') }
    @red.set_color('red')
    @green.set_color('green')
    Configuration.create(name: 'email_average_time', value: 12)
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  after :all do
    FileUtils.rm Dir.glob("#{Rails.root}/tmp/*.jpg")
  end

  describe 'write_report_to_sheet' do
    before do
      employee2
    end

    it 'should throw error if given empty array of employee ids' do
      expect { write_report_to_sheet(@worksheet, [], -1, -1) }.to raise_error
    end

    it 'should call write_employee_details' do
      expect(self).to receive(:write_employee_details).with(@worksheet, employee[:id], 1, @center)
      expect(self).to receive(:write_employee_details).with(@worksheet, employee2[:id], 14, @center)
      write_report_to_sheet(@worksheet, [employee[:id], employee2[:id]], -1, -1, center: @center)
    end

    it 'should call write_employee_scores with no group and pin ids when they are -1' do
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee[:id], @snapshot[:id], nil, nil, 1, center: @center)
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee2[:id], @snapshot[:id], nil, nil, 14, center: @center)
      write_report_to_sheet(@worksheet, [employee[:id], employee2[:id]], -1, -1, center: @center)
    end

    it 'should call write_employee_scores with correct group id' do
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee[:id], @snapshot[:id], 1, nil, 1, center: @center)
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee2[:id], @snapshot[:id], 1, nil, 14, center: @center)
      write_report_to_sheet(@worksheet, [employee[:id], employee2[:id]], 1, -1, center: @center)
    end

    it 'should call write_employee_scores with correct pin id' do
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee[:id], @snapshot[:id], nil, @pin[:id], 1, center: @center)
      expect(self).to receive(:write_employee_scores).with(@worksheet, employee2[:id], @snapshot[:id], nil, @pin[:id], 14, center: @center)
      write_report_to_sheet(@worksheet, [employee[:id], employee2[:id]], -1, @pin[:id], center: @center)
    end

    it 'should assign @last_row correctly' do
      write_report_to_sheet(@worksheet, [employee[:id]], -1, -1, center: @center)
      expect(@last_row).to eq 10
    end

    it 'should assign @last_column correctly' do
      write_report_to_sheet(@worksheet, [employee[:id]], group1[:id], -1, center: @center)
      expect(@last_column).to eq 'F'
    end
  end

  describe 'write_employee_details' do
    it 'should write employee details to report' do
      allow(self).to receive(:write_employee_image).and_return(true)
      expect(@worksheet).to receive(:write).with('D1', 'Details', @center)
      expect(@worksheet).to receive(:write).with('C2', ['First Name', employee[:first_name]], @center)
      expect(@worksheet).to receive(:write).with('C3', ['Last Name', employee[:last_name]], @center)
      expect(@worksheet).to receive(:write).with('C4', ['Age', 'N/A'], @center)
      expect(@worksheet).to receive(:write).with('C5', %w(Gender F), @center)
      expect(@worksheet).to receive(:write).with('C6', ['Seniority', employee[:rank_id].to_s], @center)
      expect(@worksheet).to receive(:write).with('C7', ['Job Title', @jt[:name]], @center)
      expect(@worksheet).to receive(:write).with('C8', ['Division', group1[:name]], @center)
      expect(@worksheet).to receive(:write).with('C9', ['Department', group1[:name]], @center)
      expect(@worksheet).to receive(:write).with('C10', ['Location', office1[:name]], @center)
      write_employee_details(@worksheet, employee[:id], 1, @center)
    end

    it 'should call write_employee_image' do
      expect(self).to receive(:write_employee_image).with(@worksheet, employee[:img_url], 1)
      write_employee_details(@worksheet, employee[:id], 1, @center)
    end
  end

  describe 'write_employee_image' do
    it 'should insert employee image to report' do
      expect(@worksheet).to receive(:insert_image).with('A1', "#{Rails.root}/tmp/Worksheet1.jpg", 0, 0, 0.1507537688442211, 0.1507537688442211)
      write_employee_image(@worksheet, employee[:img_url], 1)
    end

    it 'should write \'No image\' if image processing failed' do
      expect(@worksheet).to receive(:write).with('A1', 'No image')
      employee[:img_url] = ''
      write_employee_image(@worksheet, employee[:img_url], 1)
    end
  end

  describe 'write_employee_scores' do
    it 'should write one metric score' do
      expect(@worksheet).to receive(:write).with('F1', 'Collaboration', @center)
      expect(@worksheet).to receive(:write).with('F2', @metric_row[:score], @center)
      expect(@worksheet).to receive(:write).with('G1', 'Time in seconds', @center)
      expect(@worksheet).to receive(:write).with('G2', 0, @center)
      write_employee_scores(@worksheet, employee[:id], @snapshot[:id], 1, nil, 1, center: @center)
    end

    it 'should assign the right color to the metric score if there\'s more than one snapshot' do
      @metric_row2 = MetricScore.create(company_id: employee[:company_id], snapshot_id: 2, group_id: 1, employee_id: employee[:id], metric_id: 1, score: 0)
      @snapshot2 = Snapshot.create(company_id: 1, name: 'snapshot2')
      expect(@worksheet).to receive(:write).with('F1', 'Collaboration', @center)
      expect(@worksheet).to receive(:write).with('F2', @metric_row2[:score], @red)
      expect(@worksheet).to receive(:write).with('G1', 'Time in seconds', @center)
      expect(@worksheet).to receive(:write).with('G2', 0, @center)
      write_employee_scores(@worksheet, employee[:id], @snapshot2[:id], 1, nil, 1, center: @center, red: @red, green: @green)
    end
  end

  describe 'fetch_division' do
    it 'should return division if given group id of level 3' do
      group2
      result = fetch_division(group2[:id])
      expect(result).to eq group1[:name]
    end

    it 'should return empty string if given root group id' do
      result = fetch_division(parent_group[:id])
      expect(result).to eq ''
    end
  end

  describe 'set_column_width' do
    it 'should return length of the string if current width is not set' do
      res = set_column_width(@worksheet, 'A', 'new string', nil)
      expect(res).to eq 'new string'.length + 0.3
    end

    it 'should return length of the string if current width is smaller than given string\'s length' do
      res = set_column_width(@worksheet, 'A', 'new string', 'new string'.length - 3)
      expect(res).to eq 'new string'.length + 0.3
    end

    it 'should return current width if new string is shorter' do
      current_width = 'new string'.length + 3
      res = set_column_width(@worksheet, 'A', 'new string', 'new string'.length + 3)
      expect(res).to eq current_width
    end
  end

  describe 'column_width' do
    it 'should return length of the longest string in the array' do
      words = %w(a bb ccc dd e)
      res = column_width(words)
      expect(res).to eq 'ccc'.length
    end
  end

  describe 'score_color' do
    it 'should return green if score grows' do
      res = score_color(0, 9.99)
      expect(res).to eq 'green'
    end

    it 'should return red if score declines' do
      res = score_color(9.99, 0)
      expect(res).to eq 'red'
    end

    it 'should return nil if score stays the same' do
      res = score_color(1, 1)
      expect(res).to be nil
    end

    it 'should return nil if no old score' do
      res = score_color(nil, 1)
      expect(res).to be nil
    end
  end

  describe 'doalr_calculate' do
    it 'should return 0 if is empty list' do
      res = dollar_calculate(1, 1)
      expect(res).to eq(0)
    end
    it 'should return 120 if there 10 emails for emplyee ' do
      FactoryBot.create(:email_snapshot_data, employee_from_id:  employee[:id], employee_to_id: employee2[:id], snapshot_id: 1, n1: 3, n2: 3)
      FactoryBot.create(:email_snapshot_data, employee_from_id: 3, employee_to_id: employee[:id], snapshot_id: 1, n1: 2, n2: 1, n15: 1)
      res = dollar_calculate(1, 1)
      expect(res).to eq(120)
    end
    it 'should return 72 if there 6 emails for employee2' do
      FactoryBot.create(:email_snapshot_data, employee_from_id:  employee[:id], employee_to_id: employee2[:id], snapshot_id: 1, n1: 3, n2: 3)
      FactoryBot.create(:email_snapshot_data, employee_from_id: 3, employee_to_id: employee[:id], snapshot_id: 1, n1: 2, n2: 1, n15: 1)
      res = dollar_calculate(2, 1)
      expect(res).to eq(72)
    end
    it 'should return 0  if there no emails in the current snapshot for employee' do
      FactoryBot.create(:email_snapshot_data, employee_from_id:  employee[:id], employee_to_id: employee2[:id], snapshot_id: 1, n1: 3, n2: 3)
      FactoryBot.create(:email_snapshot_data, employee_from_id: 3, employee_to_id: employee[:id], snapshot_id: 1, n1: 2, n2: 1, n15: 1)
      res = dollar_calculate(2, 2)
      expect(res).to eq(0)
    end
  end
end
