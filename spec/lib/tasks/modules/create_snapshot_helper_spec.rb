require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/create_snapshot_helper.rb'
require 'date'

describe CreateSnapshotHelper, type:  :helper do
  describe 'Check create emails snapshot create' do
    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryBot.reload
    end

    describe do
      before do
        # Just reuing the same snapshot for this particular test
        @s = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: '2014-03-01', company_id: 1)
        @s2 = Snapshot.create(name: 'qq', timestamp: '2020-12-13', company_id: 1)

        FactoryBot.create(:raw_data_entry, date: '2013-12-12')
        FactoryBot.create(:raw_data_entry, date: '2014-12-12')
        FactoryBot.create(:raw_data_entry, date: '2014-12-13')
        FactoryBot.create(:raw_data_entry, date: '2014-03-12')
        FactoryBot.create(:raw_data_entry, date: '2014-03-13')

        create_emps('from', 'email.com', 5)
        create_emps('to', 'email.com', 5)
      end
    end
    describe 'Check create emails snapshot create' do
      after do
        DatabaseCleaner.clean_with(:truncation)
        FactoryBot.reload
      end

      describe 'exteranl domains processing' do
        external2 = 'ext2@external.com'
        date      = '2016-10-10'

        before do
          FactoryBot.create(:company)
          Domain.create!(company_id: 1, domain: 'email.com')
          @sid = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: date, company_id: 1).id
          create_emps('emp', 'email.com', 2)
        end

        it 'external entity in SQL server style' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          rde = RawDataEntry.create!(from: external2, to: "[\"\"inamir@deloitte.co.il\"\"]", company_id: 1, msg_id: 'asdf', date: date)
          puts "to: #{rde.to}"
          create_emails_for_weekly_snapshots(1, @sid, Date.parse(date))
        end
      end
    end
  end

  describe 'in_domain_emails_filter' do
    it 'should return the raw data entry filter to only emails within the domain' do
      raw_data_entry_arr = [RawDataEntry.new(from: 'from3@email.com', to: ["to3@email.com"] )]
      emps_emails_list = {'from3@email.com' => 1, 'to3@email.com' => 1}
      expect(in_domain_emails_filter(raw_data_entry_arr, emps_emails_list, 1)).to eq [[], raw_data_entry_arr]
    end
  end

  describe 'out_of_domain_emails_filter' do
    it 'should return the raw data entry filter to only emails out of the the domain' do
      raw_data_entry_arr = [RawDataEntry.new(from: 'from3@email.com', to: "{to3@email.com}", cc: '', bcc: '' )]
      emps_emails_hash = {'from3@email.com' => 1, 'to3@email.com' => 1}
      if is_sql_server_connection?
        expect(out_of_domain_emails_filter(raw_data_entry_arr, emps_emails_hash)[0].to).to eq("[]")
      else
        expect(out_of_domain_emails_filter(raw_data_entry_arr, emps_emails_hash)[0].to).to eq([])
      end
    end
  end
end
