require 'spec_helper'
#require './spec/factories/company_factory.rb'

describe SettingsController, type: :controller do
  EMPLOYEE = 2
  before do
    DatabaseCleaner.clean_with(:truncation)
    Company.create(id: 0, name: 'Comp0')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe ', #create_or_update_external_data' do
    it 'cant work with role EMP' do
      log_in_with_dummy_user_with_role(EMPLOYEE, 2)
      session = { company_id: 1 }
      response = post :create_or_update_external_data,  session: session
      expect(response).to render_template 'sessions/employee_page'
    end
  end
end
