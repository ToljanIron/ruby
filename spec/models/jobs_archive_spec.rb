require 'spec_helper'

describe JobsArchive, type: :model do
  before do
    Company.create(name: 'Test Company')
    @jobs_archive = JobsArchive.new
  end

  subject { @jobs_archive }

  it { is_expected.to respond_to(:job_id) }
  it { is_expected.to respond_to(:status) }

  describe 'with invalid data should be invalid' do
    it { is_expected.not_to be_valid }
  end
end
