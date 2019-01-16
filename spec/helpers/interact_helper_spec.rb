require 'spec_helper'
require './spec/spec_factory'
include CompanyWithMetricsFactory

describe InteractHelper, type: :helper do
  before do
    Company.find_or_create_by(id: 1, name: "Hevra10")
    Snapshot.find_or_create_by(id: 1, name: "2016-01", company_id: 1)
    Group.find_or_create_by(id: 6, name: "R&D", company_id: 1, parent_group_id: 1, color_id: 10)
    NetworkName.find_or_create_by!(id: 1, name: "Communication Flow", company_id: 1)
    create_emps('moshe', 'acme.com', 5, {gid: 6})
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryBot.reload
  end

  describe 'Interact stats' do
    describe 'question_collaboration_score' do
      it 'When more people reciprocate the score should be higher' do
        all = [
          [0,0,0,0,0],
          [1,0,1,0,0],
          [0,1,0,1,0],
          [1,1,1,0,1],
          [0,1,1,1,0]]
        fg_emails_from_matrix(all)
        res1 = question_collaboration_score(6, 1)
        NetworkSnapshotData.delete_all
        all = [
          [0,1,0,0,0],
          [1,0,1,0,0],
          [0,1,0,1,1],
          [1,1,1,0,1],
          [0,1,1,1,0]]
        fg_emails_from_matrix(all)
        res2 = question_collaboration_score(6, 1)

        expect(res1).to be < res2
      end

      it 'in a network where no one reciprocates the score shoud be zero' do
        all = [
          [0,0,0,0,0],
          [1,0,0,0,0],
          [0,1,0,0,0],
          [1,1,1,0,0],
          [0,1,1,1,0]]
        fg_emails_from_matrix(all)
        res = question_collaboration_score(6, 1)
        expect(res).to eq(0)
      end

      it 'in a network where everyone reciprocates the score shoud be one' do
        all = [
          [0,1,0,1,0],
          [1,0,1,1,1],
          [0,1,0,1,1],
          [1,1,1,0,1],
          [0,1,1,1,0]]
        fg_emails_from_matrix(all)
        res = question_collaboration_score(6, 1)
        expect(res).to eq(1)
      end
    end

    describe 'question_synergy_score' do
      it 'A full mesh network should have a score of 1' do
        all = [
          [0,1,1,1,1],
          [1,0,1,1,1],
          [1,1,0,1,1],
          [1,1,1,0,1],
          [1,1,1,1,0]]
        fg_emails_from_matrix(all)
        res = question_synergy_score(6, 1)
        expect(res).to eq(1)
      end

      it 'an empty network to have score of zero' do
         all = [
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0]]

        fg_emails_from_matrix(all)
        res = question_synergy_score(6, 1)
        expect(res).to eq(0)
      end

      it 'A fuller network should have a higher score' do
        all = [
          [0,0,1,0,0],
          [1,0,0,0,1],
          [1,0,0,1,0],
          [0,1,1,0,1],
          [1,0,1,1,0]]
        fg_emails_from_matrix(all)
        res1 = question_synergy_score(6, 1)
        NetworkSnapshotData.delete_all
        all = [
          [0,1,1,0,0],
          [1,0,1,1,1],
          [1,0,0,1,0],
          [0,1,1,0,1],
          [1,1,1,1,0]]
        fg_emails_from_matrix(all)
        res2 = question_synergy_score(6, 1)
        expect(res1).to be < res2
      end
    end

    describe 'question_centrality_score' do
      it 'A full mesh network should have 0 centrality' do
        all = [
          [0,1,1,1,1],
          [1,0,1,1,1],
          [1,1,0,1,1],
          [1,1,1,0,1],
          [1,1,1,1,0]]
        fg_emails_from_matrix(all)
        res = question_centrality_score(6, 1)
        expect(res).to eq(0)
      end

      it 'an empty network to have 1 centrality' do
         all = [
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0],
          [0,0,0,0,0]]

        fg_emails_from_matrix(all)
        res = question_centrality_score(6, 1)
        expect(res).to eq(0)
      end

      it 'a star network should have hight centrality' do
         all = [
          [0,0,1,0,0],
          [0,0,1,0,0],
          [1,1,0,1,1],
          [0,0,1,0,0],
          [0,0,1,0,0]]

        fg_emails_from_matrix(all)
        res = question_centrality_score(6, 1)
        expect(res).to be > 0.5
      end

      it 'a star network should have hight centrality' do
         all = [
          [0,0,1,0,0],
          [0,0,1,0,0],
          [1,1,0,1,1],
          [0,0,1,0,0],
          [0,0,1,0,0]]

        fg_emails_from_matrix(all)
        res1 = question_centrality_score(6, 1)
        NetworkSnapshotData.delete_all
         all = [
          [0,1,1,1,0],
          [1,0,1,0,0],
          [1,1,0,1,1],
          [0,0,1,0,1],
          [1,0,1,1,0]]

        fg_emails_from_matrix(all)
        res2 = question_centrality_score(6, 1)
        puts "res1: #{res1}, res2: #{res2}"
        expect(res1).to be > res2
      end
    end
  end
end
