require 'spec_helper'
#require './spec/factories/company_factory.rb'
ADMIN = 0
HR = 1
EMP = 2
describe BackofficeController, type: :controller do
  before do
    EventType.create!(name: 'ERROR')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end
  describe ',redirect_to admin page ' do
    it ',can redirect to admin page when the user is admin ' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      res = get :admin_page
      expect(res.status).to eq(200)
    end

    it ',cant redirect to admin page when the user is EMP ' do
      log_in_with_dummy_user_with_role(EMP, 1)
      response = get :admin_page
      expect(response).to render_template 'sessions/employee_page'
    end
  end
end
