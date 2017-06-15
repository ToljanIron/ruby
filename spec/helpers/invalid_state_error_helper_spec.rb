require 'spec_helper'
require './spec/spec_factory'
require './app/helpers/invalid_state_error_helper.rb'

describe InvalidStateErrorHelper, type: :helper do
  subject { InvalidStateErrorHelper }
  s3 = nil
  s2 = nil
  s1 = nil
  row1 = nil
  date11 = nil
  date12  = nil
  date21  = nil
  date22  = nil
  date31  = nil
  date32  = nil
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe 'invalid_snapshot_detector' do
    before do
      s1 = Snapshot.create(company_id: 1)
      s2 = Snapshot.create(company_id: 2)
      s3 = Snapshot.create(company_id: 3)
      MetricScore.create(company_id: 5, employee_id: 4, snapshot_id: s1.id, metric_id: 34, score: 43)
    end
    it 'when an empty snapshots are found should return array with ivalid snapshots ids' do
      res = invalid_snapshot_detector
      expect(res).to eq [s2.company_id, s3.company_id]
    end
  end
  describe 'unprocessed_rows_detector' do
    before do
      date_before_last_snapshot = DateTime.parse('Tue, 28 Jul 2014 17:11:05 IDT +03:00')
      s1 = Snapshot.create(company_id: 1)
      s2 = Snapshot.create(company_id: 2)
      date_after_last_snapshot = DateTime.now
      row1 = RawDataEntry.create(msg_id: 100, from: 'tester1', company_id: 1, date: date_before_last_snapshot)
      RawDataEntry.create(msg_id: 200, from: 'tester2', company_id: 2, date: date_before_last_snapshot)
      RawDataEntry.create(msg_id: 300, from: 'tester3', company_id: 2, date: date_after_last_snapshot)
    end

    it 'should return all the unprocessed row that are older then the last snapshot of the rows company' do
      res = unprocessed_rows_detector
      expected_ans = row1.company_id
      expect(res).to eq [1, 2]
    end
  end

  describe 'eventlog_invalid_state_insertion' do
    before do
      EventType.create(name: 'GENERAL_EVENT', id: 1)
    end
    it 'should write to evenlog the promlematic snapshots' do
      allow(self).to receive(:invalid_snapshot_detector) { [1] }
      allow(self).to receive(:unprocessed_rows_detector) { [2] }
      eventlog_invalid_state_insertion
      expect((EventLog.first).nil?).to eq(false)
    end
  end


  describe 'unprocessed_rows_detector' do
    before do
      date11 = DateTime.parse('Tue, 28 Jul 2014 06:00:00 IDT +03:00')
      date12 = DateTime.parse('Tue, 28 Jul 2014 06:30:00 IDT +03:00')
      date21 = DateTime.parse('Tue, 28 Jul 2014 12:01:00 IDT +03:00')
      date22 = DateTime.parse('Tue, 28 Jul 2014 12:30:00 IDT +03:00')
      date31 = DateTime.parse('Tue, 29 Jul 2014 18:01:00 IDT +03:00')
      date32 = DateTime.parse('Tue, 29 Jul 2014 18:30:00 IDT +03:00')

      RawDataEntry.create(msg_id: 100, from: 'ofer', company_id: 2, date: date11)
      RawDataEntry.create(msg_id: 101, from: 'ofer', company_id: 2, date: date12)
      RawDataEntry.create(msg_id: 102, from: 'ofer', company_id: 2, date: date21)
      RawDataEntry.create(msg_id: 103, from: 'ofer', company_id: 2, date: date22)
      RawDataEntry.create(msg_id: 104, from: 'ofer', company_id: 2, date: date31)
      RawDataEntry.create(msg_id: 105, from: 'ofer', company_id: 2, date: date32)
    end

    it 'should return all the unprocessed row that are older then the last snapshot of the rows company' do
      time = DateTime.now
      res = invalid_dates_detector(date11, 6, 2, time)
      expected_ans = DateTime.parse('Tue, 29 Jul 2014 00:00:00 IDT +03:00')
      expect(res).to eq expected_ans
    end
  end
end
