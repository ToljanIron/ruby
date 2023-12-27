require 'spec_helper'
require './spec/spec_factory'
include ImportDataHelper

#describe ExcelHelper, type: :helper, write_file: true do
describe 'ImportDataHelper' do
  before do
    DatabaseCleaner.clean_with(:truncation)
    
    @c = Company.create!(name: "Acme")
    @q = Questionnaire.create!(name: "test", company_id: @c.id, state: 'sent')
    @s=Snapshot.find_or_create_by(name: "2016-01", company_id: @c.id)
  end


  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  it 'should create groups even if there are no question participant in this group' do
    expect(Group.count).to eq(0)
    
    ImportDataHelper.load_excel_sheet(@c.id,File.open('spec/aux_files/empty_groups.xlsx'),@s.id,false)
    expect(Group.count).to eq(3)
  end

end

