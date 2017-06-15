require 'spec_helper'
require './spec/spec_factory'
require 'ruby-prof'
require 'rake'
require './spec/factories/company_with_metrics_factory.rb'
include CompanyWithMetricsFactory

describe MeasuresController, type: :controller, performance: true do
  before :all do
    puts '============================================================='
    CompanyWithMetricsFactory.create_company_data
    Rake::Task['db:precalculate_metric_scores'].invoke(1)
  end

  before(:each) do
    # login with hr user
    log_in_with_dummy_user_with_role(1)
    RubyProf.start
  end

  after(:each) do
    @time = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(@time)
    File.open("tmp/profile_data_#{@measure}.txt", 'w') { |file| printer.print(file) }
    User.delete_all
  end

  after :all do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  context '#show' do
    it 'should load advice data' do
      st = Time.now
      res = get :show, measure_type: 1, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Collaboration')
      expect(process_time).to be < 2
      @measure = 'advice'
    end

    it 'should load isolated data' do
      st = Time.now
      res = get :show, measure_type: 2, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Most Isloated')
      expect(process_time).to be < 2
      @measure = 'isolated'
    end

    it 'should load social data' do
      st = Time.now
      res = get :show, measure_type: 3, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Most Social Power')
      expect(process_time).to be < 2
      @measure = 'social'
    end

    it 'should load expert data' do
      st = Time.now
      res = get :show, measure_type: 4, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Most Expert')
      expect(process_time).to be < 2
      @measure = 'expert'
    end
  end

  context '#show_flag' do
    it 'should load risk_of_leaving data' do
      st = Time.now
      res = get :show_flag, measure_type: 0
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('At Risk of Leaving')
      expect(process_time).to be < 1
      @measure = 'risk_of_leaving'
    end

    it 'should load promising_talent data' do
      st = Time.now
      res = get :show_flag, measure_type: 1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Most Promising Talent')
      expect(process_time).to be < 1
      @measure = 'promising_talent'
    end

    it 'should load bypassed_manager data' do
      st = Time.now
      res = get :show_flag, measure_type: 2
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Most Bypassed Manager')
      expect(process_time).to be < 3
      @measure = 'bypassed_manager'
    end

    it 'should load glue data' do
      st = Time.now
      res = get :show_flag, measure_type: 3
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['graph_data']['measure_name']).to eq('Team Glue')
      expect(process_time).to be < 1
      @measure = 'glue'
    end
  end

  context 'analyze' do
    it 'should load friendship data' do
      st = Time.now
      res = get :analyze_friendship, measure_type: 1, cid: 1, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['measure_name']).to eq('Friendship')
      expect(process_time).to be < 1
      @measure = 'analyze_friendship'
    end

    it 'should load social data' do
      st = Time.now
      res = get :analyze_social, measure_type: 2, cid: 1, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['measure_name']).to eq('Social Power')
      expect(process_time).to be < 1
      @measure = 'analyze_social_power'
    end

    it 'should load expert data' do
      st = Time.now
      res = get :analyze_expert, measure_type: 3, cid: 1, gid: 1, pid: -1
      process_time = Time.now - st
      res = JSON.parse res.body
      expect(res['measure_name']).to eq('Expert')
      expect(process_time).to be < 1
      @measure = 'analyze_expert'
    end
  end
end
