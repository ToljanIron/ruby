require 'spec_helper'
require './spec/spec_factory'
#require './spec/factories/company_factory.rb'
include SessionsHelper

describe CompanyStatisticsController, type: :controller do
  before do
    CompanyStatistics.create(id: 1, snapshot_id: 2, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 2, snapshot_id: 2, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 3, snapshot_id: 2, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 4, snapshot_id: 2, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 5, snapshot_id: 2, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 6, snapshot_id: 4, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 7, snapshot_id: 3, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 8, snapshot_id: 3, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 9, snapshot_id: 3, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 10, snapshot_id: 3, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    CompanyStatistics.create(id: 11, snapshot_id: 3, statistic_title: 'Volume of Emails Analyzed', statistic_data: 'this is the data', icon_path: 'icon here', tooltip: ' yo yo yo', link_to: 'somewhere', display_order: 1)
    create_companies_data
  end
  after do
      DatabaseCleaner.clean_with(:truncation)
  end

  it 'should return all the snapshot id statistics' do
    log_in_with_dummy_user_with_role(0, 3)
    res = post :get_company_statistics, { 'sid' => 2 }
    res = JSON.parse res.body
    res = res['company_statistics']
    expect(res[0]['snapshot_id']).to eq(2)
    expect(res.length).to eq(6)
    expect(res[0]['statistic_title']).to eq('No. of Emails Analyzed')
    expect(res[1]['statistic_title']).to eq('No. of Emails Analyzed')
  end

  it 'should return the last snapshot statistics' do
    log_in_with_dummy_user_with_role(0, 3)
    Snapshot.find(3).update(timestamp: Time.now)
    res = post :get_company_statistics, { "sid" => nil }
    res = JSON.parse res.body
    res = res['company_statistics']
    expect(res[0]['snapshot_id']).to eq(3)
    expect(res.length).to eq(6)
    expect(res[0]['statistic_title']).to eq('No. of Emails Analyzed')
  end
end
