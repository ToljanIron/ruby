require 'spec_helper'

include FactoryGirl::Syntax::Methods

IN = 'to_employee_id'
OUT  = 'from_employee_id'

INIT ||= 1
REPLY ||= 2
FWD ||= 3

TO_TYPE ||= 1
CC_TYPE ||= 2
BCC_TYPE ||= 3

# This test file is for new algorithms for emails network - part of V3 version

describe AlgorithmsHelper, type: :helper do
  
  after(:each) do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end
  
  before(:each) do
    cid = 1
    gid = 3
    @s = FactoryGirl.create(:snapshot, name: 's3', company_id: cid)
    
    em1 = 'p11@email.com'
    em2 = 'p22@email.com'
    em3 = 'p33@email.com'
    em4 = 'p44@email.com'
    em5 = 'p55@email.com'
    em6 = 'p66@email.com'

    @e1 = FactoryGirl.create(:employee, email: em1, group_id: gid)
    @e2 = FactoryGirl.create(:employee, email: em2, group_id: gid)
    @e3 = FactoryGirl.create(:employee, email: em3, group_id: gid)
    @e4 = FactoryGirl.create(:employee, email: em4, group_id: gid)
    @e5 = FactoryGirl.create(:employee, email: em5, group_id: gid)
    @e6 = FactoryGirl.create(:employee, email: em6, group_id: gid)

    @n1 = FactoryGirl.create(:network_name, name: 'Communication Flow', company_id: cid)
  end

  describe 'TO field' do
    describe 'Algorithm name: spammers | to out degree | type: measure' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_outdegree_for_to_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to outdegree"' do
        higher_emp = @e1.id
        lower_emp = @e5.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to outdegree"' do
        zero_emp = @e3.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'Algorithm name: blitzed | to in degree | type: measure' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_indegree_for_to_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to indegree"' do
        higher_emp = @e5.id
        lower_emp = @e2.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to indegree"' do
        zero_emp = @e1.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end
  end

  describe 'CC field' do
    describe 'Algorithm name: ccers | cc out degree | type: measure ' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e2.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e5.id, INIT, CC_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_outdegree_for_cc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to outdegree"' do
        higher_emp = @e2.id
        lower_emp = @e1.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to outdegree"' do
        zero_emp = @e4.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'Algorithm name: cced | type: measure | cc in degree' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e2.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_indegree_for_cc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to indegree"' do
        higher_emp = @e3.id
        lower_emp = @e5.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to indegree"' do
        zero_emp = @e4.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end
  end

  describe 'BCC field' do
    describe 'Algorithm name: undercover | bcc out degree | type: measure' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        
        create_email_connection(@e2.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e5.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e2.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_outdegree_for_bcc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to outdegree"' do
        higher_emp = @e1.id
        lower_emp = @e2.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to outdegree"' do
        zero_emp = @e3.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'Algorithm name: politicos | bcc in degree | type: measure' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)        
        
        create_email_connection(@e2.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e5.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_indegree_for_bcc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "to indegree"' do
        higher_emp = @e4.id
        lower_emp = @e1.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "to indegree"' do
        zero_emp = @e3.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end
  end

  describe 'Algorithm name: emails volume | out + in degree for to + cc + bcc | type: measure' do
    before(:each) do
      create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e5.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
      
      create_email_connection(@e2.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e2.id, @e4.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e2.id, @e5.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e2.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e5.id, @e1.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

      @res = calc_emails_volume(@s.id)
      # @res.each {|m| puts "#{m}\n"}
    end

    it 'should test higher email volume' do
      higher_emp = @e1.id
      lower_emp = @e5.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end
  end

  describe "Algorithm name: blitzed | fwd's out of total to's | type: relative measure" do
    before(:each) do
      create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e2.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e3.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e4.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e4.id, FWD, CC_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e5.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e1.id, @e5.id, FWD, TO_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e2.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e3.id, @e1.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e2.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e3.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e4.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e5.id, FWD, TO_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e4.id, @e5.id, FWD, BCC_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e5.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e3.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e3.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e3.id, FWD, TO_TYPE, @s.id, 0, @n1.id)
      
      # Because of floats - any number below the threshold should be considered as zero.
      # Threshold value set arbitrarily and can be higher/lower
      @zero_threshold = 0.01

      @res = calc_relays(@s.id)
      # @res.each {|m| puts "#{m}\n"}
    end

    it 'should test higher relay measure' do
      higher_emp = @e1.id
      lower_emp = @e5.id
      higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
      lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end

    it 'should test zero relay measure' do
      zero_emp = @e2.id
      zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_indegree[:measure]).to be < @zero_threshold
    end

    it 'should test zero relay measure' do
      zero_emp = @e4.id
      zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
      expect(zero_indegree[:measure]).to be < @zero_threshold
    end
  end

  describe 'Algorithm name: deadends | total received / replies | type: relative measure' do
    before(:each) do
      create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e4.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e2.id, @e1.id, REPLY, TO_TYPE, @s.id, 0, @n1.id)

      create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e3.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, TO_TYPE, @s.id, 0, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, CC_TYPE, @s.id, 0, @n1.id)

      @res = calc_deadends(@s.id)
      # @res.each {|m| puts "#{m}\n"}
    end

    it 'should test higher sink measure' do
      higher_emp = @e2.id
      lower_emp = @e5.id
      higher_measure = @res.select{ |r| r[:id] == higher_emp }[0]
      lower_measure = @res.select{ |r| r[:id] == lower_emp }[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end

    it 'should test for undefined - missing replies and to' do
      undefined_emp = @e6.id
      undefined_measure = @res.select{ |r| r[:id] == undefined_emp }[0]
      expect(undefined_measure[:measure]).to eq(-1)
    end
  end
end