require 'spec_helper'

describe Domain, :type => :model do

  before do
    @domain = Domain.new
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
  end

  subject { @domain }

  it { is_expected.to respond_to(:company_id) }
  it { is_expected.to respond_to(:domain) }
  it { is_expected.not_to be_valid }

  describe 'find domain for company ' do
    it ', when comapny  has domain' do
      cmp = Company.create(name: 'spectory')
      Domain.create(domain: 'spectory.com', company_id: cmp.id)
      domain_list = Company.domains(cmp.id)
      expect(domain_list[0].company_id).to eq(cmp.id)
    end
    it ", when company doesn't have domain" do
      domain = 'spectory.com'
      cmp = Company.create(name: 'spectory')

      domain_list = Company.domains(cmp.id)
      expect(domain_list.all.length).to eq(0)
    end
  end
end
