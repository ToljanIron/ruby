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
    @cid = 1
    gid = 3

    @s = FactoryGirl.create(:snapshot, name: 's3', company_id: @cid)
    FactoryGirl.create(:group, id: gid, company_id: @cid, snapshot_id: @s.id)

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

    @n1 = FactoryGirl.create(:network_name, name: 'Communication Flow', company_id: @cid)
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

      it 'should test higher "cc outdegree"' do
        higher_emp = @e2.id
        lower_emp = @e1.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "cc outdegree"' do
        zero_emp = @e4.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'Algorithm name: cced | type: measure | cc in degree' do
      before(:each) do
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e2.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e2.id, @e1.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, TO_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e2.id, INIT, CC_TYPE, @s.id, 0, @n1.id)

        @res = calc_indegree_for_cc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "cc indegree"' do
        higher_emp = @e3.id
        lower_emp = @e5.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "cc indegree"' do
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

        create_email_connection(@e4.id, @e1.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e5.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        @res = calc_outdegree_for_bcc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "bcc outdegree"' do
        higher_emp = @e1.id
        lower_emp = @e2.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "bcc outdegree"' do
        zero_emp = @e3.id
        zero_indegree = @res.select{|r| r[:id]==zero_emp}[0]
        expect(zero_indegree[:measure]).to eq(0)
      end
    end

    describe 'Algorithm name: politicos | bcc in degree | type: measure' do
      before(:each) do
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e3.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e1.id, @e5.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)

        create_email_connection(@e2.id, @e1.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e3.id, INIT, TO_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, CC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e4.id, INIT, BCC_TYPE, @s.id, 0, @n1.id)
        create_email_connection(@e2.id, @e5.id, INIT, CC_TYPE, @s.id, 0, @n1.id)

        @res = calc_indegree_for_bcc_matrix(@s.id)
        # @res.each {|m| puts "#{m}\n"}
      end

      it 'should test higher "bcc indegree"' do
        higher_emp = @e4.id
        lower_emp = @e1.id
        higher_measure = @res.select{|r| r[:id]==higher_emp}[0]
        lower_measure = @res.select{|r| r[:id]==lower_emp}[0]
        expect(higher_measure[:measure]).to be > lower_measure[:measure]
      end

      it 'should test zero "bcc indegree"' do
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

  describe 'Algorithm name: external receivers | received from outside group / total received | type: relative measure' do
    before(:each) do
      gid2 = 4
      em11 = 'p111@email.com'
      em12 = 'p112@email.com'
      em13 = 'p113@email.com'

      FactoryGirl.create(:group, id: gid2, company_id: @cid, snapshot_id: @s.id)

      @eid11 = FactoryGirl.create(:employee, email: em11, group_id: gid2).id
      @eid12 = FactoryGirl.create(:employee, email: em12, group_id: gid2).id
      @eid13 = FactoryGirl.create(:employee, email: em13, group_id: gid2).id

      create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e4.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e2.id, @e1.id, REPLY, TO_TYPE, @s.id, @cid, @n1.id)

      create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @e5.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, CC_TYPE, @s.id, @cid, @n1.id)

      # Create connections for employees between groups
      create_email_connection(@e1.id, @eid11, REPLY, CC_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e1.id, @eid12, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e2.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e4.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      create_email_connection(@eid11, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid11, @e3.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid11, @e3.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid12, @e4.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      # Internal connections for gid2
      create_email_connection(@eid11, @eid12, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid13, @eid11, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid12, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      @res = calc_external_receivers(@s.id, gid2)
      @res.each {|m| puts "#{m}\n"}
    end

    it 'should test higher external receiver' do
      higher_emp = @eid13
      lower_emp = @eid11
      higher_measure = @res.select{ |r| r[:id] == higher_emp }[0]
      lower_measure = @res.select{ |r| r[:id] == lower_emp }[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end

    it 'should return correct measure' do
      score = @res.select{ |r| r[:id] == @eid13 }[0]
      expect(score[:measure] - 0.8).to be < 0.01
    end
  end

  describe 'Algorithm name: external senders | sent to outside group / total sent | type: relative measure' do
    before(:each) do
      gid2 = 4
      em11 = 'p111@email.com'
      em12 = 'p112@email.com'
      em13 = 'p113@email.com'

      FactoryGirl.create(:group, id: gid2, company_id: @cid, snapshot_id: @s.id)

      @eid11 = FactoryGirl.create(:employee, email: em11, group_id: gid2).id
      @eid12 = FactoryGirl.create(:employee, email: em12, group_id: gid2).id
      @eid13 = FactoryGirl.create(:employee, email: em13, group_id: gid2).id

      create_email_connection(@e1.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e4.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e2.id, @e1.id, REPLY, TO_TYPE, @s.id, @cid, @n1.id)

      create_email_connection(@e1.id, @e5.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @e5.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @e1.id, REPLY, CC_TYPE, @s.id, @cid, @n1.id)

      # Create connections for employees between groups
      create_email_connection(@e1.id, @eid11, REPLY, CC_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e1.id, @eid12, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e2.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e3.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e4.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@e5.id, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      create_email_connection(@eid11, @e2.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid11, @e3.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid11, @e3.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid12, @e4.id, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      # Internal connections for gid2
      create_email_connection(@eid11, @eid12, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid13, @eid11, INIT, TO_TYPE, @s.id, @cid, @n1.id)
      create_email_connection(@eid12, @eid13, INIT, TO_TYPE, @s.id, @cid, @n1.id)

      @res = calc_external_senders(@s.id, gid2)
      @res.each {|m| puts "#{m}\n"}
    end

    it 'should test higher external sender' do
      higher_emp = @eid11
      lower_emp = @eid12
      higher_measure = @res.select{ |r| r[:id] == higher_emp }[0]
      lower_measure = @res.select{ |r| r[:id] == lower_emp }[0]
      expect(higher_measure[:measure]).to be > lower_measure[:measure]
    end

    it 'should return correct measure' do
      score = @res.select{ |r| r[:id] == @eid11 }[0]
      expect(score[:measure] - 0.75).to be < 0.01
    end
  end
end
