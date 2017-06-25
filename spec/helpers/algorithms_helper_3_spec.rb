require 'spec_helper'
require './spec/spec_factory'
require './spec/factories/company_with_metrics_factory.rb'
# require './spec/factories/network_snapshot_data_factory.rb'

include FactoryGirl::Syntax::Methods

include EmailTrafficHelper

IN = 'to_employee_id'
OUT  = 'from_employee_id'

TO_MATRIX ||= 1
CC_MATRIX ||= 2
BCC_MATRIX ||= 3

INIT ||= 1
REPLY ||= 2
FWD ||= 3

TO ||= 1
CC ||= 2
BCC ||= 3

describe AlgorithmsHelper, type: :helper do
  after(:each) do
    # DatabaseCleaner.clean_with(:truncation)
    # FactoryGirl.reloadcat gem 
  end
  
  before(:all) do
      @s = FactoryGirl.create(:snapshot, name: 's3', company_id: 1)
      
      em1 = 'p11@email.com'
      em2 = 'p22@email.com'
      em3 = 'p33@email.com'
      em4 = 'p44@email.com'
      em5 = 'p55@email.com'

      cid = 1
      gid = 3

      @e1 = FactoryGirl.create(:employee, email: em1, group_id: gid)
      @e2 = FactoryGirl.create(:employee, email: em2, group_id: gid)
      @e3 = FactoryGirl.create(:employee, email: em3, group_id: gid)
      @e4 = FactoryGirl.create(:employee, email: em4, group_id: gid)
      @e5 = FactoryGirl.create(:employee, email: em5, group_id: gid)

      @n1 = FactoryGirl.create(:network_name, name: 'Communication Flow', company_id: cid)
  end

  describe 'algorithm type=measure, to, out degree' do
    after(:each) do
      NetworkSnapshotData.delete_all
    end

    describe 'should test method: EmailTrafficHelper.calc_indeg_for_specified_matrix()' do
      before(:all) do
        create_email_connection(@e1.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e1.id, INIT, BCC, @s.id, 0, @n1.id)

        @in_res = calc_indeg_for_specified_matrix(@s.id, TO_MATRIX, -1, -1)
      end

      it 'should test higher "to indegree"' do
        higher_emp = 2
        lower_emp = 5
        higher_indegree = @in_res.select{|r| r[:id]==higher_emp}[0]
        lower_indegree = @in_res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_indegree[:measure]).to be > lower_indegree[:measure]
      end

      it 'should test zero "to indegree"' do
        zero_emp = 1
        zero_indegree = @in_res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'should test method: EmailTrafficHelper.calc_outdeg_for_specified_matrix()' do
      before(:all) do
        create_email_connection(@e1.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e1.id, INIT, BCC, @s.id, 0, @n1.id)

        @out_res = calc_outdeg_for_specified_matrix(@s.id, TO_MATRIX, -1, -1)
      end

      it 'should test higher "to outdegree"' do
        higher_emp = 1
        lower_emp = 5
        higher_indegree = @out_res.select{|r| r[:id]==higher_emp}[0]
        lower_indegree = @out_res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_indegree[:measure]).to be > lower_indegree[:measure]
      end

      it 'should test zero "to outdegree"' do
        zero_emp = 3
        zero_indegree = @out_res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end
  end

  describe 'algorithm type=(relative measure), to, out degree' do
    after(:each) do
      NetworkSnapshotData.delete_all
    end

    describe 'should test method: AlgorithmsHelper.calc_relative_fwd()' do
      before(:all) do
        create_email_connection(@e1.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e2.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, FWD, CC, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, FWD, TO, @s.id, 0, @n1.id)

        create_email_connection(@e2.id, @e5.id, INIT, TO, @s.id, 0, @n1.id)

        create_email_connection(@e3.id, @e1.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e3.id, @e2.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e3.id, @e3.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e3.id, @e4.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e3.id, @e5.id, FWD, TO, @s.id, 0, @n1.id)

        create_email_connection(@e4.id, @e5.id, FWD, BCC, @s.id, 0, @n1.id)

        create_email_connection(@e5.id, @e2.id, INIT, TO, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e3.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e3.id, FWD, TO, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e3.id, FWD, TO, @s.id, 0, @n1.id)
        
        # because of floats - any number below the threshold should be considered as zero
        # value set arbitrarily and can be higher/lower
        @zero_threshold = 0.05

        @fwd_res = calc_relative_fwd(@s.id)
        @fwd_res.each {|m| puts "#{m}\n"}
      end
      it 'should test higher relay measure' do
        higher_emp = 1
        lower_emp = 5
        higher_measure = @fwd_res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @fwd_res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test approximate zero of relay measure' do
        zero_emp = 2
        zero_indegree = @fwd_res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to be < @zero_threshold
      end

      it 'should test approximate zero of relay measure' do
        zero_emp = 4
        zero_indegree = @fwd_res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to be < @zero_threshold
      end
    end
  end
end