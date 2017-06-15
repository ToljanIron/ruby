require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/create_snapshot_helper.rb'
require 'date'

describe CreateSnapshotHelper, type:  :helper do
  describe 'Test results with pin subsets' do
    before do
      @cmp1 = Company.create(name: 'A')
      @cmp2 = Company.create(name: 'B')
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    # it ', shouold create a snapshot with a correct weekly name' do    #ASAF BYEBUG DEAD CODE redundant?
    #   NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: @cmp2.id)
    #   date = '2014-01-04'
    #   create_company_snapshot_by_weeks(@cmp2.id, date, 0)
    #   fsnap = Snapshot.last
    #   expect(fsnap.name).to eq('2013-52')
    #   expect(fsnap.company_id).to eq(@cmp2.id)
    #   expect(EmailSnapshotData.where(significant_level: nil).count == 0)
    # end
    it ', shouold create a snapshot with a correct weekly name' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: @cmp2.id)
      date = '2014-01-12'
      create_company_snapshot_by_weeks(@cmp2.id, date, 0)
      fsnap = Snapshot.last
      expect(fsnap.name).to eq('2014-02')
    end
    it ', shouold create a snapshot with a correct weekly name' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: @cmp2.id)
      date = '2014-01-05'
      create_company_snapshot_by_weeks(@cmp2.id, date, 0)
      fsnap = Snapshot.last
      expect(fsnap.name).to eq('2014-01')
    end
  end

  describe 'Check create emails snapshot create' do
    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    describe do
      before do
        # Just reuing the same snapshot for this particular test
        @s = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: '2014-03-01', company_id: 1)
        @s2 = Snapshot.create(name: 'qq', timestamp: '2020-12-13', company_id: 1)

        FactoryGirl.create(:raw_data_entry, date: '2013-12-12')
        FactoryGirl.create(:raw_data_entry, date: '2014-12-12')
        FactoryGirl.create(:raw_data_entry, date: '2014-12-13')
        FactoryGirl.create(:raw_data_entry, date: '2014-03-12')
        FactoryGirl.create(:raw_data_entry, date: '2014-03-13')

        create_emps('from', 'email.com', 5)
        create_emps('to', 'email.com', 5)
      end
    end
    describe 'Check create emails snapshot create' do
      after do
        DatabaseCleaner.clean_with(:truncation)
        FactoryGirl.reload
      end

      describe 'create_emails_for_weekly_snapshots' do
        before do
          # Just reuing the same snapshot for this particular test
          @s = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: '2014-03-01', company_id: 1)
          @s2 = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: '2020-12-13', company_id: 1)
          FactoryGirl.create(:raw_data_entry, date: '2020-12-13')
          FactoryGirl.create(:raw_data_entry, date: '2020-12-13')
          FactoryGirl.create(:raw_data_entry, date: '2020-12-06')
          FactoryGirl.create(:raw_data_entry, date: '2020-12-01')
          FactoryGirl.create(:raw_data_entry, date: '2020-12-14')
          FactoryGirl.create(:raw_data_entry, date: '2020-11-28')
          FactoryGirl.create(:raw_data_entry, date: '2020-03-12')
          FactoryGirl.create(:raw_data_entry, date: '2020-03-13')
          Domain.create!(company_id: 1, domain: 'email.com')
          create_emps('from', 'email.com', 5)
          create_emps('to', 'email.com', 5)
        end

        it ', should create five entries from december' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          create_emails_for_weekly_snapshots(1, @s2.id, Date.parse('2020-12-13'))
          expect(NetworkSnapshotData.where(network_id: 123).length).to eq(4)
        end

        it 'create email_subject_snapshot_data entries' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          create_emails_for_weekly_snapshots(1, @s2.id, Date.parse('2020-12-13'))
          expect(EmailSubjectSnapshotData.count).to be > 0
          expect(EmailSubjectSnapshotData.last[:subject]).not_to be_nil
        end
      end

      describe 'exteranl domains processing' do
        emp1      = 'emp1@email.com'
        emp2      = 'emp2@email.com'
        external1 = 'ext1@external.com'
        external2 = 'ext2@external.com'
        date      = '2016-10-10'

        before do
          FactoryGirl.create(:company)
          Domain.create!(company_id: 1, domain: 'email.com')
          @sid = Snapshot.create(name: 'qq', snapshot_type: nil, timestamp: date, company_id: 1).id
          create_emps('emp', 'email.com', 2)
        end

        it 'external entity in from with two relations' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          RawDataEntry.create!(from: external1, to: "{#{emp1},#{emp2}}", company_id: 1, msg_id: 'asdf', date: date)
          create_emails_for_weekly_snapshots(1, @sid, Date.parse(date))
          expect( OverlayEntity.count ).to eq(1)
          expect( OverlaySnapshotData.count).to eq(2)
        end

        it 'external entity in to' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          RawDataEntry.create!(from: emp1, to: "{#{emp2},#{external1}}", company_id: 1, msg_id: 'asdf', date: date)
          create_emails_for_weekly_snapshots(1, @sid, Date.parse(date))
          expect( OverlayEntity.count ).to eq(1)
          expect( OverlaySnapshotData.count).to eq(1)
        end

        it 'external entity in cc and in bcc' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          RawDataEntry.create!(from: emp1, cc: "{#{emp2},#{external1}}", bcc: "{#{external2}}", company_id: 1, msg_id: 'asdf', date: date)
          create_emails_for_weekly_snapshots(1, @sid, Date.parse(date))
          expect( OverlayEntity.count ).to eq(2)
          expect( OverlaySnapshotData.count).to eq(2)
        end

        it 'external entity in SQL server style' do
          NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
          rde = RawDataEntry.create!(from: external2, to: "[\"\"inamir@deloitte.co.il\"\"]", company_id: 1, msg_id: 'asdf', date: date)
          puts "to: #{rde.to}"
          create_emails_for_weekly_snapshots(1, @sid, Date.parse(date))
          #puts "===================="
          #ap OverlayEntity.all
          #puts "===================="
        end
      end
    end
  end

  describe 'convert_monthly_snapshot_to_weekly_snapshot' do
    before do
      @s = Snapshot.create(name: 'monthly', snapshot_type: nil, timestamp: Time.new(2014, 03, 13), company_id: 1)
      @s1 = Snapshot.create(name: 'monthly-2', snapshot_type: nil, timestamp: Time.new(2014, 04, 14), company_id: 1)

      FactoryGirl.create(:raw_data_entry, date: '2014-03-02')
      FactoryGirl.create(:raw_data_entry, date: '2014-03-30')
      FactoryGirl.create(:raw_data_entry, date: '2014-03-01')
      FactoryGirl.create(:raw_data_entry, date: '2014-03-12')
      FactoryGirl.create(:raw_data_entry, date: '2014-03-13')

      create_emps('from', 'email.com', 10)
      create_emps('to', 'email.com', 10)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should create 5 weekly snapshot from monthly Snapshot' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      convert_monthly_snapshot_to_weekly_snapshot(@s.company_id, @s.id)
      expect(Snapshot.where(company_id: 1, snapshot_type: nil).count).to eq 7
      first_snapshot = Snapshot.where(company_id: 1, snapshot_type: nil).first
      expect(NetworkSnapshotData.where(snapshot_id: first_snapshot.id).count).to eq 0
    end

    it 'should create run on all the company monthly snpashot and retrun 9 weekly snapshots' do
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      convert_monthly_snapshot_to_weekly_snapshot(@s.company_id, -1)
      expect(Snapshot.where(company_id: 1, snapshot_type: nil).count).to eq 12
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

  describe 'create_network_snapshot_data_for_weekly_snapshots' do
    before do
      @start_date = Time.now
      @end_date = calculate_end_date_of_snapshot(@start_date.to_s, 1)
      @q = Questionnaire.create!(id: 1, name: 'test - quest', company_id: 1)
      @qqIndependent = QuestionnaireQuestion.create!(questionnaire_id: 1, order: 1)
      @qqDependent = QuestionnaireQuestion.create!(questionnaire_id: 1, order: 2)
      @qp1 = QuestionnaireParticipant.create(employee_id: 1, questionnaire_id: 1)
      @qp2 = QuestionnaireParticipant.create(employee_id: 2, questionnaire_id: 1)


      @s1 = Snapshot.create(name: (@start_date - 5.week).at_beginning_of_week.strftime('%-Y-%W'), timestamp: @start_date - 5.week, company_id: 1)
      @s2 = Snapshot.create(name: (@start_date.at_beginning_of_week - 1.week).strftime('%-Y-%W'), timestamp: @start_date.at_beginning_of_week - 1.week, company_id: 1)
      # NetworkSnapshotData.create!(snapshot_id: 1, network_id: 1, company_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, questionnaire_question_id: 1)
    end
    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end
    it 'should copy the network snapshot data in case there is no new data between emp 1 to emp 2 on the new snapshot' do
      NetworkSnapshotData.create!(snapshot_id: @s1.id, company_id: 1, network_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, questionnaire_question_id: 1, original_snapshot_id: @s1.id)
      duplicate_network_snapshot_data_for_weekly_snapshots(1, @s2.id)
      expect(NetworkSnapshotData.last.snapshot_id).to eq @s2.id
      expect(NetworkSnapshotData.last.original_snapshot_id).to eq @s1.id
    end

    it 'should update the network snapshot data table to its new value, in this case 1 because in the new snapshot the employee didnt answer on the dependent question' do
      QuestionReply.create!(questionnaire_id: 1, questionnaire_question_id: @qqIndependent.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: 0)
      QuestionReply.create!(questionnaire_id: 1, questionnaire_question_id: @qqIndependent.id, questionnaire_participant_id: @qp2.id, reffered_questionnaire_participant_id: @qp1.id, answer: 0)

      QuestionReply.create!(questionnaire_id: 1, questionnaire_question_id: @qqDependent.id, questionnaire_participant_id: @qp1.id, reffered_questionnaire_participant_id: @qp2.id, answer: 0)
      QuestionReply.create!(questionnaire_id: 1, questionnaire_question_id: @qqDependent.id, questionnaire_participant_id: @qp2.id, reffered_questionnaire_participant_id: @qp1.id, answer: 0)

      NetworkSnapshotData.create!(snapshot_id: @s1.id, company_id: 1, network_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, original_snapshot_id: @s1.id, questionnaire_question_id: @qqIndependent.id)
      NetworkSnapshotData.create!(snapshot_id: @s2.id, company_id: 1, network_id: 1, from_employee_id: 1, to_employee_id: 2, value: 0, original_snapshot_id: @s2.id, questionnaire_question_id: @qqIndependent.id)
      duplicate_network_snapshot_data_for_weekly_snapshots(1, @s2.id)
      expect(NetworkSnapshotData.last.value).to eq 1
      expect(NetworkSnapshotData.last.original_snapshot_id).to eq @s1.id
    end

    it 'should update the network snapshot data table to its new value, in this case 0 because in the new snapshot the employee said false on the dependent question' do
      NetworkSnapshotData.create!(snapshot_id: @s1.id, company_id: 1, network_id: 1, from_employee_id: 1, to_employee_id: 2, value: 1, questionnaire_question_id: 1, original_snapshot_id: @s1.id)
      NetworkSnapshotData.create!(snapshot_id: @s2.id, company_id: 1, network_id: 1, from_employee_id: 2, to_employee_id: 1, value: 1, questionnaire_question_id: 1, original_snapshot_id: @s1.id)
      duplicate_network_snapshot_data_for_weekly_snapshots(1, @s2.id)
      expect(NetworkSnapshotData.last.snapshot_id).to eq @s2.id
      expect(NetworkSnapshotData.where(from_employee_id: 1, to_employee_id: 2).last.snapshot_id).to eq @s2.id
    end

  end




end
