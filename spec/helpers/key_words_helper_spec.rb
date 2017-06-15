require 'spec_helper'

describe KeyWordsHelper, type: :helper do
  before do
    @comp = Company.create!(name: 'Comp1')
    @snapshot = Snapshot.create!(name: "2015-15-15", company_id: @comp.id)
    Configuration.find_or_create_by(name: 'number_of_keywords', value: 500)
    @g = Group.create!(company_id: @comp.id, name: 'g1')
    @g2 = Group.create!(company_id: @comp.id, name: 'g1')
    @e1 = Employee.create!(group_id: @g.id, external_id: 1, email: 'e1@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
    @e2 = Employee.create!(group_id: @g.id, external_id: 1, email: 'e2@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
    @e3 = Employee.create!(group_id: @g.id, external_id: 1, email: 'e3@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
    @e4 = Employee.create!(group_id: @g2.id, external_id: 1, email: 'e4@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
    @e5 = Employee.create!(group_id: @g2.id, external_id: 1, email: 'e5@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
    @e6 = Employee.create!(group_id: @g2.id, external_id: 1, email: 'e6@gmail.com', company_id: @comp.id, first_name: 'yossi', last_name: 'david')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end
  describe 'build_keywords' do
    after do
      DatabaseCleaner.clean_with(:truncation)
    end
    it 'should return filtered subjects' do
      generate_subjects_and_blacklist(@comp, 10)
      create_key_words(@snapshot.id)
      expect(no_words_from_filter_to_be_in_word_clouds(@comp.id)).to eq true
      expect(OverlayEntity.count).to be > 0
    end
    it 'should return save only 50 results to the DB' do
      generate_subjects_and_blacklist(@comp, 300)
      create_key_words(@snapshot.id)
      expect(no_words_from_filter_to_be_in_word_clouds(@comp.id)).to eq true
      expect(OverlayEntity.count).to eq 500
    end

    it 'should return save only 50 results to the DB' do
      fake_groups(@comp.id, 4)
      fake_emps(@comp.id, 10)
      generate_subjects_and_blacklist(@comp, 5)
      create_key_words(@snapshot.id)
      expect(OverlaySnapshotData.where(from_id: OverlayEntity.uniq.pluck(:id)).count).to eq OverlaySnapshotData.count
    end
  end

  describe 'static_stop_words' do
    it 'should read from a file and return an array of words' do
      result = static_stop_words
      expect(result.first).to eq('a')
      expect(result.last).to eq('נו')
    end
  end
end

def generate_subjects_and_blacklist(company, how_much_to_create)
  emps = company.employees
  emps.each do |emp1|
    (0..how_much_to_create).each do |i|
      random_sentence = LiterateRandomizer.sentence.downcase
      FilterKeyword.create!(company_id: company.id, word: random_sentence.split(' ')[0])
      EmailSubjectSnapshotData.create!(snapshot_id: Snapshot.where(company_id: company.id).first.id, employee_from_id: emp1.id, employee_to_id: emp1.id + 1, subject: random_sentence)
      # (0..999).each {EmailSubjectSnapshotData.create!(snapshot_id: Snapshot.where(company_id: company.id).first.id, employee_from_id: emp1.id, employee_to_id: emp2.id, subject: random_sentence) }
    end
  end
end

def fake_groups(cid, amount)
  (0..amount).each { Group.create(company_id: cid, name: Faker::Company.name) }
end

def fake_emps(cid, amount)
  (0..amount).each do |i|
    offset = rand(Group.count)
    Employee.create(company_id: cid, group_id: Group.offset(offset).first.id, email: Faker::Internet.free_email, first_name: Faker::Internet.user_name, last_name: Faker::Name.last_name, external_id: Faker::Number.number(10))
  end
end

def no_words_from_filter_to_be_in_word_clouds(company_id)
  words = OverlayEntity.where(company_id: company_id).pluck(:name)
  filtered_words = FilterKeyword.pluck(:word) & words
  return false if filtered_words.any?
  return true
end
