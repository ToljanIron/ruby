require 'spec_helper'

describe PinsHelper, type: :helper do
  describe ', handle pin operations as recieved from the client' do
    before do
      FactoryGirl.create(:employee, email: 'emp1@email.com')
      FactoryGirl.create(:employee, email: 'emp2@email.com')
      FactoryGirl.create(:employee, email: 'emp3@email.com')
      FactoryGirl.create(:employee, email: 'emp4@email.com')
      FactoryGirl.create(:employee, email: 'emp5@email.com')
      @cond1 = { param: 'rank_id', oper: 'notin', vals: [2] }
      @cond2 = { param: 'gender', vals: [3, 1] }
      @group1 = 5
      @group2 = 7
      @emp1 = 'a@email.com'
      @emp2 = 'b@email.com'
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
    end

    describe ', transform a conditions object as received from the client into a valid where part' do
      it ', conditions should become a valid where part ' do
        conditions = {
          conditions: [@cond1, @cond2],
          employees: [@emp1, @emp2],
          groups: [@group1, @group2]
        }
        wherepart = transform_to_wherepart conditions
        expect(wherepart).to eq("(1=1 and rank_id not in (2) and gender in (3,1) ) or email in ('#{@emp1}', '#{@emp2}') or group_id in (5,7)")
      end

      it ', conditions shuld return only 3 employess' do
        conditions1 = { employees: ['emp1@email.com', 'emp2@email.com', 'emp3@email.com'], groups: [] }
        wherepart = transform_to_wherepart conditions1
        expect(Employee.where(wherepart).where('company_id = ?', 1).count).to eq(3)
      end

      it ', conditions with empty conditions part' do
        conditions = {
          employees: [@emp1, @emp2]
        }
        wherepart = transform_to_wherepart conditions
        expect(wherepart).to eq("email in ('#{@emp1}', '#{@emp2}')")
      end

      it ', conditions with empty employees part' do
        conditions = {
          conditions: [@cond1, @cond2],
          employees: nil
        }
        wherepart = transform_to_wherepart conditions
        expect(wherepart).to eq("(1=1 and rank_id not in (2) and gender in (3,1) )")
      end
    end

    describe ', verify that the wherepart' do
      it 'that is created is syntactically correct SQL wise' do
        conditions = {
          conditions: [@cond1, @cond2],
          employees: [@emp1, @emp2]
        }
        wherepart = transform_to_wherepart conditions
        res = Employee.where(wherepart)
        expect(res).not_to include("StatementInvalid")
      end
    end
  end
end
