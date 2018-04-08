require 'nmatrix'
require 'pp'
require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
include FactoryGirl::Syntax::Methods

include CompanyWithMetricsFactory

IN = 'to_employee_id'
OUT  = 'from_employee_id'
TO_MATRIX ||= 1
CC_MATRIX ||= 2
BCC_MATRIX ||= 3

describe AlgorithmsHelper, type: :helper do

  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'most isolated' do
    all = nil
    before do
      all = [
        [0,0,0,0,0,0,0,0,0,0],
        [1,0,4,0,0,0,0,0,0,0],
        [0,3,0,6,0,0,0,0,0,0],
        [0,4,5,0,5,0,0,0,0,0],
        [0,2,0,6,0,4,0,0,0,0],
        [0,0,0,0,3,0,0,0,0,0],
        [0,0,0,0,0,4,0,0,6,0],
        [0,0,0,0,0,0,5,2,0,0],
        [0,0,0,0,0,0,8,0,0,0],
        [0,1,1,1,1,1,1,1,1,1]]

      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      create_emps('moshe', 'acme.com', 10, {gid: 6})
    end

    xit 'should rank employees by isolatation' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      expect(res[0][:id]).to eq(1)
      expect(res[0][:measure]).to eq(1)
    end

    xit 'increasing number of emails increases the score' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.most_isolated_workers(1, 6)

      all[1][5] = 4
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.most_isolated_workers(1, 6)

      score1 = res1.select { |e| e[:id] == 2}[0][:measure]
      score2 = res2.select { |e| e[:id] == 2}[0][:measure]
      expect(score2 - score1).to be > 0
    end

    it 'employee without connections should have score 0' do
      all[1][0] = 0
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      score = res.select { |e| e[:id] == 1}[0][:measure]
      expect(score).to eq(0)
    end

    it 'should return empty result for groups with less then 10 employees' do
      Employee.delete_all
      create_emps('moshe', 'acme.com', 9, {gid: 6})
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.most_isolated_workers(1, 6)
      expect(res).to eq([])
    end
  end

  describe 'powerful non-manager' do
    all = nil
    before do
      all = [
        [0,0,0,0,0,0,0,0,0,0],
        [1,0,4,0,0,0,0,0,0,0],
        [0,3,0,6,0,0,0,0,0,0],
        [0,4,5,0,5,0,0,0,0,0],
        [0,2,0,6,0,4,0,0,0,0],
        [0,0,0,0,3,0,0,0,0,0],
        [0,0,0,0,0,4,0,0,6,0],
        [0,0,0,0,0,0,5,2,0,0],
        [0,0,0,0,0,0,8,0,0,0],
        [0,1,1,1,1,1,1,1,1,1]]

      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1)
      create_emps('moshe', 'acme.com', 10, {gid: 6})
    end

    xit 'should rank employees by indegrees' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_powerful_non_managers(1, -1, 6)
      pp res
      expect(res.first[:id]).to eq(7)
      expect(res.last[:id]).to eq(10)
      expect(res[0][:measure]).to be >= res[1][:measure]
    end
  end

  describe 'sagraph' do
    all = nil
    nid = nil
    cid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
      cid = Snapshot.find(1).company_id
    end

    it 'should create a well formatted sagraph structre' do
      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
      create_emps('moshe', 'acme.com', 10, {gid: 6})
      fg_emails_from_matrix(all)

      sagraph = get_sagraph(1, nid, 6)
      inx2emp = sagraph[:inx2emp]
      emp2inx = sagraph[:emp2inx]

      expect( emp2inx[inx2emp[0]] ).to eq(0)
      expect( inx2emp[emp2inx[7]] ).to eq(7)
      expect( sagraph[:adjacencymat].shape ).to eq([10,10])
      expect( sagraph[:adjacencymat].slice(7,6) ).to eq(0.0)
      expect( sagraph[:adjacencymat].slice(7,7) ).to eq(1.0)
    end

    it 'employees with no outgoing connections should have 1 on the diagonal entry' do
      all = [
        [0,1,1,0,0,0],
        [1,0,1,0,0,0],
        [1,1,0,1,0,0],
        [0,0,1,0,1,0],
        [0,0,0,0,0,0],
        [0,0,0,1,1,0]]
      create_emps('moshe', 'acme.com', 6, {gid: 6})
      fg_emails_from_matrix(all)
      sagraph = get_sagraph(1, nid, 6)

      a = sagraph[:adjacencymat]

      expect( a.slice(4,3) ).to eq(0)
      expect( a.slice(4,4) ).to eq(1)
      expect( a.slice(4,5) ).to eq(0)
    end

    describe 'get_sa_membership_matrix' do
      gids = nil
      emp2inx = nil
      group2inx = nil
      before do
        Company.find_or_create_by(id: 1, name: "Hevra10")
        Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
        FactoryGirl.create(:group, id: 11, name: 'g1')
        FactoryGirl.create(:group, id: 12, name: 'g2')
        FactoryGirl.create(:group, id: 13, name: 'g3')
        FactoryGirl.create(:group, id: 14, name: 'g4')
        FactoryGirl.create(:employee, id: 1, group_id: 11)
        FactoryGirl.create(:employee, id: 2, group_id: 11)
        FactoryGirl.create(:employee, id: 3, group_id: 12)
        FactoryGirl.create(:employee, id: 4, group_id: 12)
        FactoryGirl.create(:employee, id: 5, group_id: 12)
        FactoryGirl.create(:employee, id: 6, group_id: 14)
        FactoryGirl.create(:employee, id: 7, group_id: 14)
        FactoryGirl.create(:employee, id: 8, group_id: 14)
        gids = Group.pluck(:id)
        emp2inx = {}
        group2inx = {}
        (0..7).each do |i|
          emp2inx[i+1] = i
          group2inx[i + 11] = i if i < 4
        end
      end

      it 'should be well formed' do
        m = get_sa_membership_matrix(emp2inx, group2inx, gids)
        expect(m.shape).to eq([8,4])
        expect(m.column(2).to_a.flatten).to eq([0,0,0,0,0,0,0,0])
        expect(m.row(2).to_a).to eq([0,1,0,0])
      end
    end

    describe 'get_sameetings' do
      before do
        Company.find_or_create_by(id: 1, name: "Hevra10")
        Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
        FactoryGirl.create(:group, id: 11, name: 'g1')
        FactoryGirl.create(:employee, id: 1, group_id: 11)
        FactoryGirl.create(:employee, id: 2, group_id: 11)
        FactoryGirl.create(:employee, id: 3, group_id: 11)
        FactoryGirl.create(:employee, id: 4, group_id: 11)
        FactoryGirl.create(:employee, id: 5, group_id: 11)

        MeetingsSnapshotData.create!(id: 1, snapshot_id: 1, company_id: 1)
        MeetingsSnapshotData.create!(id: 2, snapshot_id: 1, company_id: 1)
        MeetingsSnapshotData.create!(id: 3, snapshot_id: 1, company_id: 1)

        MeetingAttendee.create!(meeting_id: 1, employee_id: 1)
        MeetingAttendee.create!(meeting_id: 1, employee_id: 3)
        MeetingAttendee.create!(meeting_id: 1, employee_id: 5)
        MeetingAttendee.create!(meeting_id: 2, employee_id: 1)
        MeetingAttendee.create!(meeting_id: 3, employee_id: 1)
        MeetingAttendee.create!(meeting_id: 2, employee_id: 2)
        MeetingAttendee.create!(meeting_id: 3, employee_id: 3)
        MeetingAttendee.create!(meeting_id: 3, employee_id: 4)
      end

      it 'should be well formed' do
        m = get_sameetings_block(1, 11)
        meetingsmat = m[:meetingsmat]
        expect(meetingsmat.shape).to eq([5,3])
        expect(meetingsmat.column(1).to_a.flatten).to eq([1,1,0,0,0])
        expect(meetingsmat.row(2).to_a).to eq([1,0,1])
      end

      it 'should have a valid meeting2inx' do
        m = get_sameetings_block(1, 11)
        meeting2inx = m[:meeting2inx]
        expect( meeting2inx[3] ).to eq(2)
      end

      it 'should have a valid inx2meeting' do
        m = get_sameetings_block(1, 11)
        inx2meeting = m[:inx2meeting]
        expect( inx2meeting[1] ).to eq(2)
      end
    end
  end

  describe 'observers' do
    before do
      Company.find_or_create_by!(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by!(id: 1, name: "2016-01", company_id: 1, timestamp: Time.now)
      NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1)
      FactoryGirl.create(:group, id: 11, name: 'g1')
      create_emps('moshe', 'acme.com', 4, {gid: 11, sid: 1})

      MeetingsSnapshotData.create!(id: 1, snapshot_id: 1, company_id: 1, duration_in_minutes: 10)
      MeetingsSnapshotData.create!(id: 2, snapshot_id: 1, company_id: 1, duration_in_minutes: 20)
      MeetingsSnapshotData.create!(id: 3, snapshot_id: 1, company_id: 1, duration_in_minutes: 30)
      MeetingsSnapshotData.create!(id: 4, snapshot_id: 1, company_id: 1, duration_in_minutes: 40)

      MeetingAttendee.create!(meeting_id: 1, employee_id: 1)
      MeetingAttendee.create!(meeting_id: 1, employee_id: 3)
      MeetingAttendee.create!(meeting_id: 2, employee_id: 1)
      MeetingAttendee.create!(meeting_id: 2, employee_id: 2)
      MeetingAttendee.create!(meeting_id: 3, employee_id: 3)
      MeetingAttendee.create!(meeting_id: 3, employee_id: 4)
      MeetingAttendee.create!(meeting_id: 4, employee_id: 4)
      MeetingAttendee.create!(meeting_id: 4, employee_id: 2)
    end

    it 'participants in meeting 4 had very little email traffic' do
      all = [
        [0,5,5,5],
        [5,0,5,1],
        [5,5,0,5],
        [5,0,5,0]]
      fg_emails_from_matrix(all)

      res = calculate_observers(1, 11, -1)
      emp1 = res.find { |r| r[:id] == 1}
      emp4 = res.find { |r| r[:id] == 4}
      expect(emp1[:measure]).to eq(0)
      expect(emp4[:measure]).to eq(40)
    end

    it 'there should be no observers because all traffic is similar' do
      all = [
        [0,1,1,1],
        [1,0,1,1],
        [1,1,0,1],
        [1,1,1,0]]
      fg_emails_from_matrix(all)

      res = calculate_observers(1, 11, -1)
      observers_time = res.reduce(0) { |sum, e| sum += e[:measure] }
      expect(observers_time).to eq(0)
    end
  end

  describe 'bottlnecks' do
    all = nil
    nid = nil
    cid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
      Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
      nid = NetworkName.find_or_create_by!(id: 123, name: "Communication Flow", company_id: 1).id
      cid = Snapshot.find(1).company_id
    end

    it 'should create a well formatted sagraph structre' do
      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
      create_emps('moshe', 'acme.com', 10, {gid: 6})
      fg_emails_from_matrix(all)

      bns = AlgorithmsHelper.calculate_bottlenecks(1, nid, 6)
      expect(bns[4][:measure]).to eq(10.0)
    end
  end

  describe 'reverse_scores' do
    arr = [
      {a: 'a1', s: 2},
      {a: 'a2', s: -1},
      {a: 'a3', s: 5},
      {a: 'a4', s: 1},
      {a: 'a5', s: 4}
    ]
    it 'should revers the scores' do
      res = AlgorithmsHelper.reverse_scores(arr, :s)
      expect(res[2][:s]).to eq(0)
      expect(res[4][:s]).to eq(1)
    end
  end

  describe 'calculate_connectors' do
    all = nil
    nid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.create!(id: 1, name: "2016-01", company_id: 1, timestamp: '2016-01-01 00:12:12')
      nid = NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1).id

      FactoryGirl.create(:group, id: 11, name: 'g1')
      FactoryGirl.create(:group, id: 12, name: 'g2', parent_group_id: 11)
      FactoryGirl.create(:group, id: 13, name: 'g3', parent_group_id: 11)
      FactoryGirl.create(:group, id: 14, name: 'g4', parent_group_id: 11)
      FactoryGirl.create(:employee, id: 1, group_id: 11)
      FactoryGirl.create(:employee, id: 2, group_id: 11)
      FactoryGirl.create(:employee, id: 3, group_id: 12)
      FactoryGirl.create(:employee, id: 4, group_id: 12)
      FactoryGirl.create(:employee, id: 5, group_id: 12)
      FactoryGirl.create(:employee, id: 6, group_id: 13)
      FactoryGirl.create(:employee, id: 7, group_id: 14)
      FactoryGirl.create(:employee, id: 8, group_id: 14)
      FactoryGirl.create(:employee, id: 9, group_id: 14)
      FactoryGirl.create(:employee, id: 10,group_id: 14)

      all = [
        [0,1,1,0,0,0,0,0,0,0],
        [1,0,1,0,0,0,0,0,0,0],
        [1,1,0,1,0,0,0,0,0,0],
        [0,0,1,0,1,0,0,0,0,0],
        [0,0,0,1,0,1,1,1,1,1],
        [0,0,0,1,1,0,1,1,1,1],
        [0,0,0,0,1,1,0,1,1,1],
        [0,0,0,0,1,1,1,0,1,1],
        [0,0,0,0,1,1,1,1,0,1],
        [0,0,0,0,1,1,1,1,1,0]]
    end

    it 'result should be well formed' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      expect(res.length).to eq(10)
      expect(res.first[:id]).not_to be_nil
      expect(res.first[:measure]).not_to be_nil
    end

    it 'employee sending only to one group should get 0' do
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      id  = res[3][:id]
      mes = res[3][:measure]
      expect(id).to eq(4)
      expect(mes).to eq(0.0)
    end

    it 'sending to more groups results in higher scores' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][8] = 1
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to be < res2[0][:measure]
    end

    it 'less balanced traffic has lower score' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][2] = 2
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to be > res2[0][:measure]
    end

    it 'increasing overall traffic proportionally ...' do
      fg_emails_from_matrix(all)
      res1 = AlgorithmsHelper.calculate_connectors(1, nid, 11)
      all[0][1] = 2
      all[0][2] = 2
      NetworkSnapshotData.delete_all
      fg_emails_from_matrix(all)
      res2 = AlgorithmsHelper.calculate_connectors(1, nid, 11)

      expect(res1[0][:measure]).to eq(res2[0][:measure])
    end
  end

  describe 'calculate_non_reciprocity_between_employees' do
    all = nil
    nid = nil
    before do
      Company.find_or_create_by(id: 1, name: "Hevra10")
      Snapshot.create!(id: 1, name: "2016-01", company_id: 1, timestamp: '2016-01-01 00:12:12')
      nid = NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1).id

      FactoryGirl.create(:group, id: 11, name: 'g1')
      FactoryGirl.create(:employee, id: 1, group_id: 11)
      FactoryGirl.create(:employee, id: 2, group_id: 11)
      FactoryGirl.create(:employee, id: 3, group_id: 11)
    end

    it 'should be zero only if traffic is symetric' do
      all = [
        [0,3,3],
        [3,0,2],
        [1,2,0]]
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)
      expect(res.find{ |r| r[:id] == 1}[:measure]).not_to eq(0)
      expect(res.find{ |r| r[:id] == 2}[:measure]).to eq(0)
      expect(res.find{ |r| r[:id] == 3}[:measure]).not_to eq(0)
    end

    it 'should be 1 and -1 if there is no reciprocity at all' do
      all = [
        [0,3,3],
        [0,0,2],
        [0,0,0]]
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)
      expect(res.find{ |r| r[:id] == 1}[:measure]).to eq(1.0)
      expect(res.find{ |r| r[:id] == 3}[:measure]).to eq(-1.0)
    end

    it 'should be 1 and -1 if there is no reciprocity at all' do
      all = [
        [0,3,3],
        [3,0,2],
        [2,2,0]]
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)
      reciprocity0 = res.find{ |r| r[:id] == 1}[:measure]

      all = [
        [0,3,4],
        [3,0,2],
        [2,2,0]]
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)
      reciprocity1 = res.find{ |r| r[:id] == 1}[:measure]

      all = [
        [0,3,4],
        [1,0,2],
        [2,2,0]]
      fg_emails_from_matrix(all)
      res = AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)
      reciprocity2 = res.find{ |r| r[:id] == 1}[:measure]

      expect(reciprocity0).to be < reciprocity1
      expect(reciprocity1).to be < reciprocity2
    end

    it 'should not crash if there is no email trffic' do
      expect{ AlgorithmsHelper.calculate_non_reciprocity_between_employees(1, -1, 11)}.not_to raise_error
    end
  end

  describe 'group_non_reciprocity' do
    it 'should be high if receiving is low' do
      FactoryGirl.create(:cds_metric_score, score: 10, id: 1, group_id: 6, algorithm_id: 300)
      FactoryGirl.create(:cds_metric_score, score: 10, id: 2, group_id: 6, algorithm_id: 301)
      res1 = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      CdsMetricScore.find(1).update!(score: 1)
      res2 = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect(res1).to be < res2
    end

    it 'should be low if receiving is high' do
      FactoryGirl.create(:cds_metric_score, score: 10, id: 1, group_id: 6, algorithm_id: 300)
      FactoryGirl.create(:cds_metric_score, score: 10, id: 2, group_id: 6, algorithm_id: 301)
      res1 = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      CdsMetricScore.find(1).update!(score: 30)
      res2 = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect(res1).to be > res2
    end

    it 'should be NA if there are no receiving and sending' do
      res = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect( res ).to eq(-99999)
    end

    it 'shhould be NA if both values are zero' do
      FactoryGirl.create(:cds_metric_score, score: 0, id: 1, group_id: 6, algorithm_id: 300)
      FactoryGirl.create(:cds_metric_score, score: 0, id: 2, group_id: 6, algorithm_id: 301)
      res = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect( res ).to eq(-99999)
    end

    it 'should be zero if sending is zero' do
      FactoryGirl.create(:cds_metric_score, score: 10, id: 1, group_id: 6, algorithm_id: 300)
      FactoryGirl.create(:cds_metric_score, score:  0, id: 2, group_id: 6, algorithm_id: 301)
      res = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect( res ).to eq(0.0)
    end

    it 'should be close to one if receving is zero' do
      FactoryGirl.create(:cds_metric_score, score:  0, id: 1, group_id: 6, algorithm_id: 300)
      FactoryGirl.create(:cds_metric_score, score: 10, id: 2, group_id: 6, algorithm_id: 301)
      res = AlgorithmsHelper.group_non_reciprocity(1,6)[0][:measure]
      expect( res ).to be > 0.99
    end
  end
end
