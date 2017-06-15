require 'spec_helper'
#require './spec/factories/company_factory'

def create_colors
  (1..12).each do
    rand_color = '#' + "%06x" % (rand * 0xffffff)
    Color.create(rgb: rand_color)
  end
end

employee_details = {
  external_id:      '123',
  first_name:       'fst_name',
  middle_name:      'mid_name',
  last_name:        'lst_name',
  email:            'main@email.com',
  alias_emails:     'alias1@email.com#  alias2@email.com# alias3@email.com#',
  role:        1,
  rank:             2,
  job_title:        'village idiot',
  date_of_birth:    '2000-01-22',
  gender:           'male',
  marital_status:   'single',
  work_start_date:  '2003-01-22',
  qualifications:   'company_specific qualifications',
  home_address:     'Abbey road 17',
  office_address:   'Abu dhabi',
  position_scope:   '80',
  group_name:       'IT',
  delete:           ''
}

describe ImportDataHelper, type: :helper do
  before do
    create_colors
    @company = Company.create(name: 'Acme Inc.')
    log_in_with_dummy_user_with_role('hr', @company.id)
    @e1, @e2 = FactoryGirl.create_list(:employee, 2)
    @csv_type = ''

    @src_csv = './spec/helpers/advice_csv.csv'
    @src_target_csv = []
    CSV.foreach(@src_csv, :headers => false) do |row|
      @src_target_csv.push(row)
    end
    @csv_target_advice = CSV.open("./spec/helpers/advice.csv", 'w')
    @advice_header = ["employee", "advicee", "advice_flag", "snapshot"]
    @e1 = Employee.create!(email: 'yaniv@spectory.com', external_id: 1, company_id: 1, first_name: 'test', last_name: 'test')
    @e2 = Employee.create!(email: 'vali@spectory.com', external_id: 2, company_id: 1, first_name: 'test', last_name: 'test')
    @e3 = Employee.create!(email: 'hadas@spectory.com', external_id: 3, company_id: 1, first_name: 'test', last_name: 'test')
    @ans_formatted = [["1", "2", "1", "2015-01-01"], ["1", "3", "1", "2015-01-02"]]
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  it 'should create header' do
    ImportDataHelper.create_headers(@src_target_csv, "./spec/helpers/advice")
    src = []
    CSV.foreach('./spec/helpers/advice.csv', :headers => false) do |row|
      src.push(row)
    end
    expect(src[0]).to eql(@advice_header)
  end

  it 'should get_ans_formatted' do
    ImportDataHelper.create_headers(@src_target_csv, "./spec/helpers/advice")
    ans = ImportDataHelper.get_ans_formatted(@src_csv, @src_target_csv)
    expect(ans).to eql(@ans_formatted)
  end

  it 'should write_question_to_csv' do
    ImportDataHelper.write_question_to_csv(@ans_formatted, "./spec/helpers/advice")
    src = []
    CSV.foreach('./spec/helpers/advice.csv', :headers => false) do |row|
      src.push(row)
    end
    expect(src[0]).to eql(@ans_formatted[0])
    expect(src[1]).to eql(@ans_formatted[1])
  end

  it 'shoud return error string when csv_type is unknown' do
    res = import_data_from_csv_to_db(1, 'csv text', nil, 'invalid csv type', false, nil)
    expect(res).to eq('import_company_data_from_csv: unknown csv type')
  end

  describe ', importing company groups structure csv' do
    before do
      @csv_type = ImportDataHelper::CSV_TYPES[:groups_csv]
      @g1 = FactoryGirl.create(:group, name: 'G1', company_id: @company.id)
      FactoryGirl.create(:group, name: 'G2', company_id: @company.id, parent_group_id: @g1.id)
    end

    describe 'lift_csv_to_context_list' do
      it ', should have an error if the csv is invalid on the first line' do
        cl = lift_csv_to_context_list(@company.id, 'G1', nil, @csv_type, false, nil)
        expect(context_list_errors(cl).length).to be 1
      end

      it ', should return an error if the csv is invalid on the second line' do
        cl = lift_csv_to_context_list(@company.id, "G1, G2,\r\nG3", nil, @csv_type, false, nil)
        expect(context_list_errors(cl).length).to be 1
      end

      it ', should create a context for each group' do
        cl = lift_csv_to_context_list(@company.id, "G1, G2,\r\nG3, G4,\r\nG5, G6,", nil, @csv_type, false, nil)
        expect(cl.length).to be 6
      end
    end

    describe 'import_company_data_from_csv' do
      it ', should insert new groups to the db' do
        csv_line = "parent_group_name,child_group_name,delete\r\nG1, G2,\r\nG3, G4,\r\nG5, G6,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        expect(Group.count).to eq 6
      end

      it ', should not insert the same group twice' do
        csv_line = "parent_group_name,child_group_name,delete\r\nG1, G2,\r\nG2, G3,\r\nG4, G2,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        expect(Group.count).to eq 4
      end

      it ', should insert with best effort even if there is an error' do
        csv_line = "parent_group_name,child_group_name,delete\r\nG1, G2,\r\nG3, #{'a' * 510},\r\nG4, G5,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        expect(Group.count).to eq 5
      end

      it ', should reconnet child with higest group as parent' do
        g1, g2 = FactoryGirl.create_list(:group, 2)
        g1.update(parent_group_id: @g1.id, name: g1[:name].strip.titleize)
        g2.update(parent_group_id: g1.id, name: g2[:name].strip.titleize)
        csv_line = "#{g1.name}, #{g2.name},delete\r\n"
        import_data_from_csv_to_db(g1.company.id, csv_line, nil, @csv_type, false, nil)
        expect(Group.find(g2.id)[:parent_group_id]).to eq(g1.id)
      end
    end

    describe 'connecting groups' do
      it ', should update a child with the parent id in new groups' do
        csv_line = "parent_group_name,child_group_name,delete\r\nG3, G4,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        g3 = Group.find_by(company_id: @company.id, name: 'G3')
        g4 = Group.find_by(company_id: @company.id, name: 'G4')
        expect(g4.parent_group_id).to eq g3.id
      end

      it ', should update a child with the parent id in existing groups' do
        csv_line = "parent_group_name,child_group_name,delete\r\nG1, G4,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        g4 = Group.find_by(company_id: @company.id, name: 'G4')
        expect(g4.parent_group_id).to eq @g1.id
      end
    end
  end

  describe ', importing employees details csv' do
    before do
      @csv_type = ImportDataHelper::CSV_TYPES[:employee_csv]
      @valid_csv_line = employee_details.values.to_a.join(',')
      @valid_csv_headers = employee_details.keys.to_a.join(',')
      @invalid_line = ',aa,bb,cc,'
    end

    describe ', lift_csv_to_context_list' do
      it ', should have an error if the csv is invalid on the first line' do
        cl = lift_csv_to_context_list(@company.id, @invalid_line, nil, @csv_type, false, nil)
        expect(context_list_errors(cl).length).to be 1
      end

      it ', should return an error if the csv is invalid on the second line' do
        csv = "#{@valid_csv_line}\r\n#{@invalid_line}"
        cl = lift_csv_to_context_list(@company.id, csv, nil, @csv_type, false, nil)
        expect(context_list_errors(cl).length).to be 1
      end

      it ', should create a context for each group' do
        cl = lift_csv_to_context_list(@company.id, @valid_csv_line, nil, @csv_type, false, nil)
        expect(cl.length).to be 1
      end
    end

    describe ', with delete field' do
      it ', should not create new employee' do
        csv_type = nil
        Group.create(name: 'IT', company_id: @company.id)
        ed = employee_details.dup
        ed[:delete] = 'delete'
        csv_line = ed.values.to_a.join(',')
        csv_type = ImportDataHelper::CSV_TYPES[:employee_csv]
        expect { import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil) }.to_not change { Employee.count }
      end
    end
  end

  describe 'importing management relation csv' do
    e1 = e2 = nil
    before do
      @csv_type = ImportDataHelper::CSV_TYPES[:managment_relation_csv]
    end

    it ', should create ManagementRelation when first csv line is valid' do
      e1, e2 = FactoryGirl.create_list(:employee, 2)
      csv_line = "manager_external_id,employee_external_id,relation_type,delete\r\n" + "#{e1.external_id},#{e2.external_id}, direct,"
      expect { import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil) }.to change { EmployeeManagementRelation.count }.by(1)
    end

    describe ', when realtion exist' do
      e1 = e2 = relation = nil
      before do
        e1, e2 = FactoryGirl.create_list(:employee, 2)
        relation = EmployeeManagementRelation.create(manager_id: e1.id, employee_id: e2.id, relation_type: 'direct')
      end

      it ', should not create ManagementRelation when already exist' do
        csv_line = "manager_external_id,employee_external_id,relation_type,delete\r\n" + "#{e1.external_id}, #{e2.external_id}, direct,"
        expect { import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil) }.not_to change { EmployeeManagementRelation.count }
      end

      it ', should update ManagementRelation when already exist' do
        old_relation_type = EmployeeManagementRelation.find(relation[:id])[:relation_type]
        csv_line = "manager_external_id,employee_external_id,relation_type,delete\r\n" + "#{e1.external_id}, #{e2.external_id}, professional,"
        import_data_from_csv_to_db(@company.id, csv_line, nil, @csv_type, false, nil)
        res = EmployeeManagementRelation.find(relation[:id])[:relation_type]
        expect(res).not_to eq(old_relation_type)
      end
    end
  end
end
