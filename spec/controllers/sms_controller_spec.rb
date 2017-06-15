# frozen_string_literal: true
require 'spec_helper'

describe SmsController, type: :controller do
  before do
    Company.create(name: 'test')
    Language.create(name: 'English')
    Language.create(name: 'Hebrew', direction: 1)
    allow(SmsHelper).to receive(:generate_message).and_return(message: 'success')
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe '#receive_and_respond' do
    let(:employee) { FactoryGirl.create(:employee, id_number: '1231231231', first_name: 'qwe', last_name: 'qwe', company_id: 1) }
    let(:questionnaire) { FactoryGirl.create(:questionnaire, company_id: 1, language_id: 1) }
    let!(:questionnaire_participant) { FactoryGirl.create(:questionnaire_participant, employee_id: employee.id, questionnaire_id: questionnaire.id, token: 'qwe123') }

    it 'should render xml' do
      response = post :receive_and_respond, 'Body': '1231231231'
      expect(response.body).to include('<message>success</message>')
      expect(EventLog.first.message.include?('Finished')).to be_truthy
    end

    describe 'if employee is found' do
      it 'should generate_message with text and link if no sms text is chosen for questionnaire' do
        expect(SmsHelper).to receive(:generate_message).with("Welcome to StepAhead employee evaluation questionnaire. Click on the following link to start the questionnaire: #{questionnaire_participant.create_link}")
        post :receive_and_respond, 'Body': '1231231231'
      end

      it 'should generate_message with questionnaire specific sms text' do
        questionnaire.update(sms_text: 'I am a weird guy, click this link:')
        expect(SmsHelper).to receive(:generate_message).with("I am a weird guy, click this link: #{questionnaire_participant.create_link}")
        post :receive_and_respond, 'Body': '1231231231'
      end
    end

    describe 'if employee not found' do
      it 'should generate_message with no record text' do
        expect(SmsHelper).to receive(:generate_message).with('Welcome to StepAhead employee evaluation questionnaire. The ID number you sent is not registered. Send the correct ID again or contact support.')
        post :receive_and_respond, 'Body': 'noexistent'
        expect(EventLog.first.message.include?('Failed')).to be_truthy
      end
    end
  end

  describe 'check ID numbers with control digit' do
    let(:employee) { FactoryGirl.create(:employee, id_number: '12345678', first_name: 'qwe', last_name: 'qwe', company_id: 1) }
    let(:questionnaire) { FactoryGirl.create(:questionnaire, company_id: 1, language_id: 1) }
    let!(:questionnaire_participant) { FactoryGirl.create(:questionnaire_participant, employee_id: employee.id, questionnaire_id: questionnaire.id, token: 'qwe123') }

    it 'should find employee even with a leading zero' do
      response = post :receive_and_respond, 'Body': '012345678'
      expect(EventLog.first.message.include?('Finished')).to be_truthy
      expect(response.body).to include('<message>success</message>')
    end
  end
end
