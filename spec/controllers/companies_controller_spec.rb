require 'spec_helper'
#require './spec/factories/company_factory.rb'
describe CompaniesController, type: :controller do
  ADMIN = 0
  HR = 1
  EMP = 2
  COMPANY_NAME = 'spec-spec'

  before do
    EventType.create!(name: 'ERROR')
  end
  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  describe '#create' do
    before do
      @params = {
        data: {
          name: 'new company',
          domains: [{ name: 'domain1.com', service: 'gmail' },
                    { name: 'domain2.com', service: 'exchange' },
                    { name: 'domain3.com' }]
        }
      }
    end

    it 'should create new company' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      post :create, @params
      expect(Company.last[:name]).to eq 'new company'
    end

    it 'should return error if company with this name already exists' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      Company.create(name: 'new company')
      response = post :create, @params
      expect(JSON.parse(response.body)).to eq('error' => 'Error creating company')
    end

    it 'should create domains for each domain in params array' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      post :create, @params
      expect(Domain.pluck(:domain, :company_id)).to include ['domain1.com', 1]
      expect(Domain.pluck(:domain, :company_id)).to include ['domain2.com', 1]
      expect(Domain.pluck(:domain, :company_id)).to include ['domain3.com', 1]
    end

    it 'should return error if this domain already exists' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      Domain.create(company_id: 1, domain: 'domain1.com')
      post :create, @params
      expect(JSON.parse(response.body)).to eq('error' => 'Error creating company')
    end

    it 'should create email service for each domain with email service' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      post :create, @params
      expect(EmailService.pluck(:name)).to include 'gmail'
      expect(EmailService.pluck(:name)).to include 'exchange'
    end

    it 'should not create email service if it is blank' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      post :create, @params
      expect(EmailService.count).to eq 2
    end
  end

  describe ',update company name' do
    before do
      Company.create(name: 'comp')
    end

    it ',can rename the company name from comp to spec-spec' do
      log_in_with_dummy_user_with_role(ADMIN, 1)
      company = { id: 1, name: COMPANY_NAME }
      post :update, company: company
      expect(Company.first.name).to eq(COMPANY_NAME)
    end

    it ',not rename the company name from comp to spec-spec when role in hr' do
      log_in_with_dummy_user_with_role(HR, 1)
      company = { id: 1, name: COMPANY_NAME }
      expect { post :update, company: company }.to raise_error(Pundit::NotAuthorizedError)
    end

    it ',not rename the company name from comp to spec-spec when role in emp' do
      log_in_with_dummy_user_with_role(EMP, 1)
      company = { id: 1, name: COMPANY_NAME }
      post :update, company: company
      expect(Company.first.name).to_not eq(COMPANY_NAME)
      response = post :update, company: company
      expect(response).to render_template 'sessions/employee_page'
    end
  end
end
