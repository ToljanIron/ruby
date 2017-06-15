require 'spec_helper'
require 'line_processing_context.rb'

def create_colors
  (1..12).each do
    rand_color = '#%06x' % (rand * 0xffffff)
    Color.create(rgb: rand_color)
  end
end

class DummyClass
  include LineProcessingContextClasses
end

describe LineProcessingContextClasses do
  before do
    create_colors
    @company = Company.create(name: 'dumb and dumber')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', GroupLineProcessingContext' do
    subject  { LineProcessingContextClasses::GroupLineProcessingContext.new(0, 0, @company.id) }

    describe ', create_if_not_existing' do
      before do
        @group_in_db = FactoryGirl.create(:group, name: 'name', company_id: @company.id)
        @group_out_of_db = FactoryGirl.build(:group, name: 'other_name', company_id: @company.id)
      end

      it ', when company_id is invalid' do
        subject.attrs.merge!(company_id: 1111, name: @group_in_db.name)
        expect { subject.create_if_not_existing }.not_to change { Group.count }
      end

      it ', when group already exists' do
        subject.attrs.merge!(name: @group_in_db.name)
        group_count = Group.count
        subject.create_if_not_existing
        expect(group_count).to eq(Group.count)
      end
      it ', when group does not exists' do
        subject.attrs.merge!(name: @group_out_of_db.name)
        expect { subject.create_if_not_existing }.to change { Group.count }.by(1)
      end
      it ', when group attrs are invalid' do
        subject.attrs.merge!(company_id: nil, name: 'something')
        error_log_size =  subject.error_log.count
        subject.create_if_not_existing
        expect(error_log_size + 1).to eq(subject.error_log.count)
      end
    end

    describe ', connect' do
      it 'when parent group exists' do
        g1, g2 = FactoryGirl.create_list(:group, 2)
        res = LineProcessingContextClasses::GroupLineProcessingContext.new(0, 0, @company.id, g1.name)
        res.attrs.merge!(
          company_id: g2.company_id,
          name:       g2.name
          )
        res.connect
        g2 = Group.find_by(id: g2.id)
        expect(g2.parent_group_id).to eq(g1.id)
      end

      it 'when parent group does not exists' do
        g1 = FactoryGirl.build(:group)
        g2 = FactoryGirl.create(:group)
        res = LineProcessingContextClasses::GroupLineProcessingContext.new(0, 0, @company.id, g1.name)
        res.attrs = {
          company_id: g2.company_id,
          name:       g2.name
        }
        res.connect
        g2 = Group.find_by(id: g2.id)
        expect(g2.parent_group_id).to be_nil
      end
    end

    describe 'delete' do
      it 'when parent group exists, should reconnect to the higest group' do
        g0, g1, g2 = FactoryGirl.create_list(:group, 3)
        g1.update(parent_group_id: g0.id)
        g2.update(parent_group_id: g1.id)
        res = LineProcessingContextClasses::GroupLineProcessingContext.new(0, 0, @company.id, g1.name)
        res.attrs.merge!(
          name:       g2.name,
          delete: true
          )
        res.delete
        g2 = Group.find_by(id: g2.id)
        expect(g2.parent_group_id).to eq(g0.id)
      end
    end
  end

  describe ', EmployeeLineProcessingContext' do
    subject = nil

    before do
      subject = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id)
      @employee_in_db = FactoryGirl.create(:employee)
      @employee_out_of_db = FactoryGirl.build(:employee)
    end

    describe ', create_if_not_existing' do
      it ', when company_id is invalid' do
        subject.attrs.merge!(company_id: 1111)
        expect { subject.create_if_not_existing }.not_to change { Employee.count }
      end

      it ', when employee already exists' do
        subject.attrs.merge!(external_id: @employee_in_db.external_id)
        employee_count =  Employee.count
        subject.create_if_not_existing
        expect(employee_count).to eq(Employee.count)
      end
      it ', when employee does not exists' do
        subject.attrs.merge!(
          external_id:  @employee_out_of_db.external_id,
          first_name:   @employee_out_of_db.first_name,
          last_name:    @employee_out_of_db.last_name,
          email:        @employee_out_of_db.email,
          date_of_birth: '1999-01-01',
          work_start_date: '2005-01-01'
          )
        expect { subject.create_if_not_existing }.to change { Employee.count }.by(1)
      end
      it ', when employee attrs are invalid' do
        subject.attrs.merge!(company_id: nil)
        error_log_size = subject.error_log.count
        subject.create_if_not_existing
        expect(error_log_size + 1).to eq(subject.error_log.count)
      end

      describe ', delete attribute' do
        it ', when employee exists' do
          subject.attrs.merge!(external_id: @employee_in_db[:external_id])
          expect { subject.create_if_not_existing }.to_not change { Employee.count }
        end
        it ', when employee doesnt exists' do
          subject.attrs[:external_id] = @employee_out_of_db[:external_id]
          expect { subject.create_if_not_existing }.to_not change { Employee.count }
        end
      end
    end

    describe ', delete' do
      before do
        subject.attrs.merge!(delete: true)
      end
      it ', when employee already exists' do
        subject.attrs.merge!(external_id: @employee_in_db.external_id)
        expect { subject.delete }.to change { Employee.count }.by(-1)
      end
      it ', when employee doesnt exists' do
        subject.attrs.merge!(external_id: @employee_out_of_db.external_id)
        expect { subject.delete }.not_to change { Employee.count }
      end
      it ', when same external id but differnt company' do
        other_company = Company.create(name: 'other company')
        subject.attrs.merge!(company_id: other_company.id, external_id: @employee_out_of_db.external_id)
        expect { subject.delete }.not_to change { Employee.count }
      end
    end

    describe ', connect' do
      describe ', group_name attribute' do
        it ', when group exists' do
          g = FactoryGirl.create(:group)
          satellite_tables_attrs = { group_name: g.name }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          @cl.connect
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e[:group_id]).to eq g.id
        end
        describe ', when group does not exists' do
          it 'should add entry to error log' do
            satellite_tables_attrs = { group_name: 'garbge' }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            expect { @cl.connect }.to change { @cl.error_log.count }.by(1)
          end
        end
      end

      describe ', marital_status attribute' do
        it ', when marital status exists' do
          m = MaritalStatus.create(name: 'divorced')
          satellite_tables_attrs = { marital_status: m.name }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          @cl.connect
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e[:marital_status_id]).to eq m.id
        end
        describe ', when marital status does not exist' do
          it 'should not add entry to error log' do
            satellite_tables_attrs = { marital_status: 'divorced' }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            expect { @cl.connect }.to change { @cl.error_log.count }.by(0)
          end
          it 'should not update employee.marital_status_id' do
            satellite_tables_attrs = { marital_status: 'divorced' }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            @cl.connect
            e = Employee.find_by(id: @employee_in_db.id)
            expect(e[:marital_status_id]).to be_nil
          end
        end
      end

      describe ', office attribute' do
        it ', when office  exists' do
          o = Office.create(name: 'maskit 7', company_id: @company.id)
          office_length = Office.all.size
          satellite_tables_attrs = { office_address: o.name }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          @cl.connect
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e[:office_id]).to eq o.id
          expect(office_length).to eq(Office.count)
        end
        describe ', office doesnt exist' do
          it 'should add an office entry to the office table' do
            office_length =  Office.all.size
            satellite_tables_attrs = { office_address: 'maskit 7' }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            @cl.connect
            Employee.find_by(id: @employee_in_db.id)
            expect(office_length + 1).to eq(Office.count)
          end
          it 'should update employee.office_id' do
            satellite_tables_attrs = { office_address: 'maskit 7' }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            @cl.connect
            e = Employee.find_by(id: @employee_in_db.id)
            expect(e[:office_id]).to eq(Office.last.id)
          end
          it ', when office with same name exists under other company' do
            other_company = Company.create(name: 'other Company')
            o = Office.create(name: 'maskit 7', company_id: other_company.id)
            satellite_tables_attrs = { office_address: o.name }
            @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
            @cl.attrs[:external_id] = @employee_in_db[:external_id]
            expect { @cl.connect }.to change {  Office.count }.by(1)
            e = Employee.find_by(id: @employee_in_db.id)
            expect(e[:office_id]).to eq Office.last.id
          end
        end
      end

      describe ', role attribute', only: true do
        it 'when does not role exsits' do
          satellite_tables_attrs = { role: 'role' }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          expect { @cl.connect }.to change { Role.count }.by(1)
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e.role).to eq Role.find_by(name: 'role')
        end
        it 'when role exsits' do
          r = Role.create(name: 'role', company_id: @company.id)
          satellite_tables_attrs = { role: 'role' }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          @cl.connect
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e.role).to eq r
        end
        it 'when role with same exsits under other company' do
          other_company = Company.create(name: 'other Company')
          Role.create(name: 'role', company_id: other_company.id)
          satellite_tables_attrs = { role: 'role' }
          @cl = LineProcessingContextClasses::EmployeeLineProcessingContext.new(0, 0, @company.id, satellite_tables_attrs)
          @cl.attrs[:external_id] = @employee_in_db[:external_id]
          expect { @cl.connect }.to change { Role.count }.by(1)
          e = Employee.find_by(id: @employee_in_db.id)
          expect(e.role).to eq Role.find_by(name: 'role', company_id: @company.id)
        end
      end
    end
  end

  describe ', RelationLineProcessingContext' do
    subject  { LineProcessingContextClasses::RelationLineProcessingContext.new(0, 0, @company.id) }
    before do
      emp1, emp2 = FactoryGirl.create_list(:employee, 2)
      @valid_attrs = {
        manager_external_id: emp1[:external_id],
        employee_external_id: emp2[:external_id],
        relation_type: 'direct'
      }
      @invalid_attrs = {
        manager_external_id: emp1[:external_id],
        employee_external_id: emp2[:external_id],
        relation_type: '-1'
      }
    end

    it ', when company is invalid' do
      subject.attrs.merge!(@valid_attrs)
      subject.attrs[:company_id] = 1111
      expect { subject.create_if_not_existing }.not_to change { EmployeeManagementRelation.count }
    end
    describe ', create_if_not_existing' do
      it 'when employees and relation type are valid' do
        subject.attrs.merge!(@valid_attrs)
        expect { subject.create_if_not_existing }.to change { EmployeeManagementRelation.count }.by(1)
      end
      it 'when employees and relation type are valid' do
        subject.attrs = @invalid_attrs
        expect { subject.create_if_not_existing }.not_to change { EmployeeManagementRelation.count }
        expect { subject.create_if_not_existing }.to change { subject.error_log.count }.by(1)
      end
    end
  end

  describe ', RelationLineProcessingContext' do
    subject  { LineProcessingContextClasses::RelationLineProcessingContext.new(0, 0, @company.id) }
    before do
      emp1, emp2 = FactoryGirl.create_list(:employee, 2)
      @valid_attrs = {
        manager_external_id: emp1[:external_id],
        employee_external_id: emp2[:external_id],
        relation_type: 0,
        delete: false,
        version: 'v1'
      }
      @invalid_attrs = {
        manager_external_id: emp1[:external_id],
        employee_external_id: emp2[:external_id],
        relation_type: 5,
        delete: false,
        version: 'v1'
      }
    end
    describe ', create_if_not_existing' do
      it ', when company_id is invalid' do
        subject.attrs.merge! @valid_attrs
        subject.attrs[:company_id] = 1111
        expect { subject.create_if_not_existing }.not_to change { EmployeeManagementRelation.count }
      end

      it 'when employees and relation type are valid' do
        subject.attrs.merge! @valid_attrs
        expect { subject.create_if_not_existing }.to change { EmployeeManagementRelation.count }.by(1)
      end
      it 'when employees and relation type are valid' do
        subject.attrs.merge! @invalid_attrs
        expect { subject.create_if_not_existing }.not_to change { EmployeeManagementRelation.count }
        expect { subject.create_if_not_existing }.to change { subject.error_log.count }.by(1)
      end
      it 'when delete is true' do
        subject.attrs.merge! @valid_attrs
        subject.attrs[:delete] = true
        expect { subject.create_if_not_existing }.not_to change { EmployeeManagementRelation.count }
      end
    end

    describe ', delete' do
      e1 = e2 = nil
      before do
        e1, e2 = FactoryGirl.create_list(:employee, 2)
        EmployeeManagementRelation.create(manager_id: e1.id, employee_id: e2.id, relation_type: 0)
      end
      it 'when relation exists' do
        subject.attrs.merge!(
          manager_external_id: e1[:external_id],
          employee_external_id: e2[:external_id],
          relation_type: 0,
          delete: true
          )
        subject.attrs[:delete] = true
        expect { subject.delete }.to change { EmployeeManagementRelation.count }.by(-1)
      end
      it 'when relation exists but company_id doesnt match' do
        other_company = Company.create(name: 'other Company')
        subject.attrs.merge!(
          company_id: other_company.id,
          manager_external_id: e1[:external_id],
          employee_external_id: e2[:external_id],
          relation_type: 0,
          delete: true
          )
        expect { subject.delete }.not_to change { EmployeeManagementRelation.count }
      end
      it 'when relation doesnt exists' do
        subject.attrs.merge!(
          manager_external_id: e2[:external_id],
          employee_external_id: e1[:external_id],
          relation_type: 0,
          delete: true
          )
        subject.attrs[:delete] = true
        expect { subject.delete }.not_to change { EmployeeManagementRelation.count }
      end
    end
  end

  # backend only:

  describe ', NetworkLineProcessingContext' do
    emp1, emp2 = nil
    subject = nil
    csv_type = nil
    snapshot_date = '2015-28'
    before do
      @valid_attrs = nil
      csv_type = nil
      csv_type = NetworkName.create(name: 'Friendship', company_id: @company.id)
      subject = LineProcessingContextClasses::NetworkLineProcessingContext.new(0, 0, @company.id, csv_type)
      # emp1, emp2 = FactoryGirl.create_list(:employee, 2)
      email_1 = 'p1@email.com'
      email_2 = 'p2@email.com'
      emp1 = FactoryGirl.create(:employee, external_id: 1, email: email_1, company_id: @company.id)
      emp2 = FactoryGirl.create(:employee, external_id: 2, email: email_2, company_id: @company.id)
      @valid_attrs = {
        from_employee_id: emp1[:external_id],
        to_employee_id: emp2[:external_id],
        value: 1,
        snapshot: '2011-01-18',
        csv_type: csv_type.name,
        version:  'v2'
      }
    end
    after do
      DatabaseCleaner.clean_with(:truncation)
    end
    describe ', create_if_not_existing' do
      it ',when NetworkName doesnt exist should create a new NetworkName' do
        Snapshot.create(company_id: emp1[:company_id], name: snapshot_date)
        subject.attrs.merge! @valid_attrs
        @new_valid_attrs = {
          csv_type: 'new_network'
        }
        subject.attrs.merge! @new_valid_attrs
        expect { subject.create_if_not_existing }.to change { NetworkName.count }.by(1)
      end
      it ',when NetworkName exist should not create a new NetworkName' do
        Snapshot.create(company_id: emp1[:company_id], name: snapshot_date)
        subject.attrs.merge! @valid_attrs
        @new_valid_attrs = {
          csv_type: 'Friendship'
        }
        subject.attrs.merge! @new_valid_attrs
        expect { subject.create_if_not_existing }.to change { NetworkName.count }.by(0)
      end
      it ',when Snapshot doesnt exist should create a new snapshot' do
        Snapshot.create(company_id: emp1[:company_id], name: snapshot_date)
        subject.attrs.merge! @valid_attrs
        @new_valid_attrs = {
          csv_type: 'new_network',
          snapshot: '2011-01-19',
        }
        subject.attrs.merge! @new_valid_attrs
        expect { subject.create_if_not_existing }.to change { Snapshot.count }.by(1)
      end
      it ',when Snapshot exist should not create a new snapshot' do
        Snapshot.create(company_id: emp1[:company_id], name: snapshot_date)
        subject.attrs.merge! @valid_attrs
        @new_valid_attrs = {
          csv_type: 'new_network',
          snapshot: '2015-07-12',
        }
        subject.attrs.merge! @new_valid_attrs
        expect { subject.create_if_not_existing }.to change { Snapshot.count }.by(0)
      end
      it ',when should create new NetworkSnapshotData doesnt exist' do
        Snapshot.create(company_id: emp1[:company_id], name: snapshot_date)
        subject.attrs.merge! @valid_attrs
        subject.create_if_not_existing
        expect(NetworkSnapshotData.last.value).to eq(@valid_attrs[:value])
        expect(NetworkSnapshotData.last.from_employee_id).to eq(@valid_attrs[:from_employee_id].to_i)
        expect(NetworkSnapshotData.last.to_employee_id).to eq(@valid_attrs[:to_employee_id].to_i)
        expect(NetworkSnapshotData.last.network_id).to eq(csv_type.id)
      end
    end
  end
end
