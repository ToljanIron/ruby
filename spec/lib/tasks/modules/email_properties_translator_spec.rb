require 'spec_helper.rb'
require './lib/tasks/modules/email_properities_translator.rb'

class DummyClass
  include EmailPropertiesTranslator
end

describe EmailPropertiesTranslator do
  before do
    @dummy_class = DummyClass.new
    @dummy_class.extend(EmailPropertiesTranslator)
    @email_relation = nil
  end

  after { DatabaseCleaner.clean_with(:truncation) }

  subject { @dummy_class }

  describe ', find_multiplicity_type' do
    describe ', when ONE2ONE' do
      describe ', with one TO' do
        before do
          rde = RawDataEntry.new
          rde[:to] = ['someone@company.com']
          rde[:cc] = []
          rde[:bcc] = []
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2ONE' do
          expect(@multiplicity).to eq(EmailPropertiesTranslator::ONE2ONE)
        end
      end

      describe ', with one CC' do
        before do
          rde = RawDataEntry.new
          rde[:to] = []
          rde[:cc] = ['someone@company.com']
          rde[:bcc] = []
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2ONE' do
          expect(@multiplicity).to eq(EmailPropertiesTranslator::ONE2ONE)
        end
      end

      describe ', with one BCC' do
        before do
          rde = RawDataEntry.new
          rde[:to] = []
          rde[:cc] = []
          rde[:bcc] = ['someone@company.com']
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2ONE' do
          expect(@multiplicity).to eq(EmailPropertiesTranslator::ONE2ONE)
        end
      end
    end

    describe ', when ONE2MANY' do
      describe ", with multiple TO's" do
        before do
          rde = RawDataEntry.new
          rde[:to] = ['someone@company.com', 'someone2@company.com']
          rde[:cc] = []
          rde[:bcc] = []
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2MANY' do
          @multiplicityshould == 1
        end
      end

      describe ", with multiple CC's" do
        before do
          rde = RawDataEntry.new
          rde[:to] = []
          rde[:cc] = ['someone@company.com', 'someone2@company.com']
          rde[:bcc] = []
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2MANY' do
          expect(@multiplicity).to eq(EmailPropertiesTranslator::ONE2MANY)
        end
      end

      describe ", with multiple BCC's" do
        before do
          rde = RawDataEntry.new
          rde[:to] = []
          rde[:cc] = []
          rde[:bcc] = ['someone@company.com', 'someone2@company.com']
          @multiplicity = subject.send(:find_multiplicity_type, rde)
        end

        it ', should be ONE2MANY' do
          expect(@multiplicity).to eq(2)
        end
      end

      describe ', with multiple recipents' do
        describe ', with TO & cc' do
          before do
            rde = RawDataEntry.new
            rde[:to] = ['someone@company.com']
            rde[:cc] = ['someone3@company.com']
            rde[:bcc] = []
            @multiplicity = subject.send(:find_multiplicity_type, rde)
          end

          it ', should be ONE2MANY' do
            expect(@multiplicity).to eq(2)
          end
        end

        describe ', with TO & bcc' do
          before do
            rde = RawDataEntry.new
            rde[:to] = ['someone@company.com']
            rde[:cc] = []
            rde[:bcc] = ['someone3@company.com']
            @multiplicity = subject.send(:find_multiplicity_type, rde)
          end

          it ', should be ONE2MANY' do
            expect(@multiplicity).to eq(2)
          end
        end
      end
    end
  end

  describe ', find_email_relation' do
    describe ', when fwd' do
      before do
        rde = RawDataEntry.new(fwd: true)
        @email_relation = subject.send(:find_email_relation, rde)
      end

      it ', should be FORWARD' do
        expect(@email_relation).to eq(EmailPropertiesTranslator::FORWARD)
      end
    end

    describe ', when reply' do
      it ', should be REPLY email with subject RE:' do
        rde = RawDataEntry.new(subject: 'RE: some reply')
        @email_relation = subject.send(:find_email_relation, rde)
        expect(@email_relation).to eq(EmailPropertiesTranslator::REPLY)
      end

      it ', should be REPLY email with subject Re:' do
        rde = RawDataEntry.new(subject: 'Re: some reply')
        @email_relation = subject.send(:find_email_relation, rde)
        expect(@email_relation).to eq(EmailPropertiesTranslator::REPLY)
      end

      it ', should be REPLY email with subject re:' do
        rde = RawDataEntry.new(subject: 'Re: some reply')
        @email_relation = subject.send(:find_email_relation, rde)
        expect(@email_relation).to eq(EmailPropertiesTranslator::REPLY)
      end


      it ', should not be REPLY email with subject R:' do
        rde = RawDataEntry.new(subject: 'R: some reply')
        @email_relation = subject.send(:find_email_relation, rde)
        expect(@email_relation).not_to eq(EmailPropertiesTranslator::REPLY)
      end

      it ', should not be REPLY email with subject Rq:' do
        rde = RawDataEntry.new(subject: 'Rq: some reply')
        @email_relation = subject.send(:find_email_relation, rde)
        expect(@email_relation).not_to eq(EmailPropertiesTranslator::REPLY)
      end
    end

    describe ', when not reply or fwd' do
      before do
        rde = RawDataEntry.new
        @email_relation = subject.send(:find_email_relation, rde)
      end

      it ', should be INITIATE' do
        expect(@email_relation).to eq(EmailPropertiesTranslator::INITIATE)
      end
    end
  end

  describe ', convert_relations_to_arr' do
    before do
      @sender = 0
      @to = [10, 11]
      @cc = [20, 21]
      @bcc = [30, 31, 32, 33]
      @recipents = [@to, @cc, @bcc]
      @multiplicity = EmailPropertiesTranslator::ONE2ONE
      @email_relation = EmailPropertiesTranslator::INITIATE
      @res = subject.send(:convert_relations_to_arr, @sender, @recipents, @multiplicity, @email_relation)
    end

    it ', should have same number of relations as recipents' do
      expect(@res.length).to eq(@to.length + @cc.length + @bcc.length)
    end

    it ', relation should be unique' do
      @res.each do |rel, rel2|
        expect(rel).not_to eq(rel2)
      end
    end
  end

  describe ', convert_emails_to_employee_ids' do
    before do
      FactoryBot.create_list(:employee, 3)
      @cmp_id = 0
    end
  end

  describe ', in_comany_doamin_list' do
    before do
      @cmp = Company.create(name: 'comapany INC')
      @email = 'user@comp.com'
      Domain.create(domain: 'comp.com', company_id: @cmp.id)
    end
    it ',should return the true for correct domain  ' do
      res =  subject.send(:in_comany_doamin_list, @email, @cmp.id)
      expect(res).to eq(true)
    end
  end
end
