require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'
require './spec/factories/company_with_metrics_factory.rb'
require 'date'

include CompanyWithMetricsFactory

describe PrecalculateMetricScoresForCustomDataSystemHelper, type: :helper do
  let(:group1) { FactoryGirl.create(:group, id: 1, company_id: 1, name: 'group1') }
  let(:group2) { FactoryGirl.create(:group, id: 2, company_id: 1, name: 'group2') }
  let(:pin1) { FactoryGirl.create(:pin, id: 1, company_id: 1, name: 'pin1') }
  let(:pin2) { FactoryGirl.create(:pin, id: 2, company_id: 1, name: 'pin2') }
  let(:employee1) { FactoryGirl.create(:group_employee, id: 1, company_id: 1, group_id: 1) }
  let(:employee3) { FactoryGirl.create(:group_employee, id: 3, company_id: 1, group_id: 2) }
  let(:employee2) { FactoryGirl.create(:employee, id: 2, company_id: 2, email: 'emp2@e.com', external_id: 2) }

  let(:mock_all_besides_flags) {
      allow_any_instance_of(Algorithm).to receive(:run).and_call_original
      allow(ParamsToArgsHelper).to receive(:calculate_group_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:calculate_analyze_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:calculate_per_snapshot_and_pin).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:calculate_pair_for_specific_relation_per_snapshot_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:get_most_social_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_isolated_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:calculate_pair_advice_per_snapshot_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:get_advice_relation_in_network_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:get_advice_out_network_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:find_most_expert_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_promising_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_bypassed_manager_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:team_glue_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:get_trust_in_network_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:get_trust_out_network_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:centrality_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:central_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:in_the_loop_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:politician_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:total_activity_centrality_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:delegator_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:knowledge_distributor_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:politically_active_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_isolated_group_active_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_aloof_group_active_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:most_self_sufficient_group_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
      allow(ParamsToArgsHelper).to receive(:at_risk_of_leaving_to_args).and_return([{ id: 1, measure: @mock_score / 2 }])
  }

  before do
    DatabaseCleaner.clean_with(:truncation)

    create_company_metrics_company_1
    create_company_metrics_company_2
    create_algorithms_and_algorithm_type
    create_network_names
    create_metric_names
    Company.create(id: 1, name: 'company1')
    Snapshot.create(id: 1, company_id: 1, name: 'first')
    group1
    pin1
    EmployeesPin.create(pin_id: 1, employee_id: 1)
    employee1
    @measure_ids = []
    @flag_ids = []
    @analyze_ids = []
    Algorithm.where(algorithm_type_id: 1).all.each do |row|
      @measure_ids.push(row.id)
    end
    Algorithm.where(algorithm_type_id: 2).all.each do |row|
      @flag_ids.push(row.id)
    end
    Algorithm.where(algorithm_type_id: 3).all.each do |row|
      @analyze_ids.push(row.id)
    end
    @algos_num = Algorithm.all.length
    @mock_score = 1.00
    allow_any_instance_of(Algorithm).to receive(:run).and_return([{ id: 1, measure: @mock_score }])
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'for company with one employee and one snapshot' do
    describe ', when only company is specified' do
      before do
        cds_calculate_scores(1, -1, -1, -1, -1)
        @company_data = CdsMetricScore.where(company_id: 1)
      end

      describe 'measure scores' do
        before do
          @company_measure_data = @company_data.select { |row| @measure_ids.include?(row[:algorithm_id]) }
        end

        xit 'should be saved for an employee on company level' do
          no_group_measure_data = @company_measure_data.select { |row| row[:group_id].nil? && row[:pin_id].nil? }
          expect(no_group_measure_data.length).to be > 0
        end

        it 'should be received from calculate_measure_helper' do
          employee_measure_data = @company_measure_data.select { |row| row[:employee_id] == 1 }
          expect(employee_measure_data.map(&:score).sample).to eq(@mock_score)
        end

        it 'should be change the pin status to saved after calculate' do
          expect(Pin.last.status).to eq('saved')
          expect(Pin.first.status).to_not eq('in_progress')
        end
      end

      describe 'flag scores' do
        before do
          @company_flag_data = @company_data.select { |row| @flag_ids.include?(row[:algorithm_id]) }
        end

        it 'should be saved for an employee on group level' do
          group_flag_data = @company_flag_data.select { |row| row[:group_id] == employee1[:group_id] }
          expect(group_flag_data.length).to eq @flag_ids.length
        end
      end

      it 'should throw exception if no such company' do
        expect { cds_calculate_scores(9000, -1, -1, -1, -1) }.to raise_error('No company found!')
      end
    end

    describe 'when group id is specified' do
      before do
        group2
      end

      it 'should precalculate metric scores only for this group' do
        cds_calculate_scores(1, 1, -1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1)
        group1_data = CdsMetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(group1_data.select { |row| row[:algorithm_id] == mid }).to eq(company1_data.select { |row| row[:algorithm_id] == mid })
      end
      it 'should not change the Pins status' do
        cds_calculate_scores(1, 1, -1, -1, -1)
        expect(Pin.first.status).to eq('pre_create_pin')
      end

      it 'should precalculate metric scores only for this group if company is not specified' do
        cds_calculate_scores(-1, 1, -1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1)
        group1_data = CdsMetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(group1_data.select { |row| row[:algorithm_id] == mid }).to eq(company1_data.select { |row| row[:algorithm_id] == mid })
      end

      it 'should throw exception if no such group' do
        expect { cds_calculate_scores(-1, 9000, -1, -1, -1) }.to raise_error
      end

      it 'should throw exception if no such group if company is specified' do
        expect { cds_calculate_scores(1, 9000, -1, -1, -1) }.to raise_error('No group found!')
      end

      it 'should throw exception if the group doesn\'t belong to the company' do
        Company.create(id: 2, name: 'company2')
        Snapshot.create(id: 2, company_id: 2, name: 'second')
        expect { cds_calculate_scores(2, 1, -1, -1, -1) }.to raise_error('No group found!')
      end

      describe ', when data already exists' do
        before do
          employee3
          cds_calculate_scores(1, -1, -1, -1, -1)
          @measure_group_data_before = CdsMetricScore.where(group_id: 1).select { |row| @measure_ids.include? row[:algorithm_id] }
          @flag_group_data_before = CdsMetricScore.where(group_id: 1).select { |row| @flag_ids.include? row[:algorithm_id] }
          @group2_data = CdsMetricScore.where(group_id: 2)
          @pin1_data = CdsMetricScore.where(pin_id: 1)
          @company_level_data = CdsMetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          # mocking changes in data
          allow_any_instance_of(Algorithm).to receive(:run).and_return([])
          cds_calculate_scores(1, 1, -1, -1, -1)
        end

        it 'should rewrite group measure data if it exists' do
          group_data = CdsMetricScore.where(group_id: 1).select { |row| @measure_ids.include? row[:algorithm_id] }
          # check that it consists only of the data for employees in the group
          expect(group_data.select { |row| row[:score] == @mock_score / 2 }).to eq group_data
        end

        it 'should rewrite group flag data if it exists' do
          group_data = CdsMetricScore.where(group_id: 1).select { |row| @flag_ids.include? row[:algorithm_id] }
          # check that it consists only of the data for employees in the group
          expect(group_data.empty?).to be true
        end

        it 'should leave other groups data unchanged' do
          group2_new_data = CdsMetricScore.where(group_id: 2)
          expect(@group2_data).to eq group2_new_data
        end

        it 'should leave other pins data unchanged' do
          pin1_new_data = CdsMetricScore.where(pin_id: 1)
          expect(@pin1_data).to eq pin1_new_data
        end

        it 'should leave company level data unchanged' do
          company_level_new_data = CdsMetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          expect(@company_level_data).to eq company_level_new_data
        end
      end
    end

    describe 'when pin id is specified' do
      it 'should precalculate metric scores only for given pin' do
        cds_calculate_scores(1, -1, 1, -1, -1)
        all_data = CdsMetricScore.all
        pin_data = CdsMetricScore.where(pin_id: pin1.id)
        expect(all_data.length).to be > 0
        expect(all_data.length).to eq(pin_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(all_data.select { |row| row[:algorithm_id] == mid }.first).to eq(pin_data.select { |row| row[:algorithm_id] == mid }.first)
      end

      it 'should precalculate metric scores only for given pin if company is not specified' do
        cds_calculate_scores(-1, -1, 1, -1, -1)
        all_data = CdsMetricScore.all
        pin_data = CdsMetricScore.where(pin_id: pin1.id)
        expect(all_data.length).to be > 0
        expect(all_data.length).to eq(pin_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(all_data.select { |row| row[:algorithm_id] == mid }.first).to eq(pin_data.select { |row| row[:algorithm_id] == mid }.first)
      end

      it 'should throw exception if no such pin' do
        expect { cds_calculate_scores(-1, -1, 9000, -1, -1) }.to raise_error
      end

      it 'should throw exception if no such pin if company is specified' do
        expect { cds_calculate_scores(1, -1, 9000, -1, -1) }.to raise_error('No pin found!')
      end

      it 'should throw exception if the group doesn\'t belong to the company' do
        Company.create(id: 2, name: 'company2')
        Snapshot.create(id: 2, company_id: 2, name: 'second')
        expect { cds_calculate_scores(2, -1, 1, -1, -1) }.to raise_error('No pin found!')
      end

      describe ', when data already exists' do
        before do
          pin2
          EmployeesPin.create(pin_id: 2, employee_id: 1)
          cds_calculate_scores(1, -1, -1, -1, -1)
          @measure_pin_data_before = MetricScore.where(pin_id: 1).select { |row| @measure_ids.include? row[:algorithm_id] }
          @flag_pin_data_before = MetricScore.where(pin_id: 1).select { |row| @flag_ids.include? row[:algorithm_id] }
          @group_data = MetricScore.where(group_id: 1)
          @pin2_data = MetricScore.where(pin_id: 2)
          @company_level_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          # mocking changes in data
          allow_any_instance_of(Algorithm).to receive(:run).and_return([{ id: 1, measure: @mock_score }])
          # allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
          # allow(self).to receive(:calculate_flags).and_return([])
          # recalculating for group 1
          cds_calculate_scores(1, -1, 1, -1, -1)
        end

        it 'should rewrite pin measure data' do
          pin_data = MetricScore.where(pin_id: 1).select { |row| @measure_ids.include? row[:algorithm_id] }
          # check that it consists only of the data for employees in the group
          expect(pin_data.select { |row| row[:score] == @mock_score / 2 }).to eq pin_data
        end

        it 'should rewrite pin flag data' do
          pin_data = MetricScore.where(pin_id: 1).select { |row| @flag_ids.include? row[:algorithm_id] }
          # check that it consists only of the data for employees in the group
          expect(pin_data.empty?).to be true
        end

        it 'should leave other groups data unchanged' do
          group_new_data = MetricScore.where(group_id: 1)
          expect(@group_data).to eq group_new_data
        end

        it 'should leave other pins data unchanged' do
          pin2_new_data = MetricScore.where(pin_id: 2)
          expect(@pin2_data).to eq pin2_new_data
        end

        it 'should leave company level data unchanged' do
          company_level_new_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          expect(@company_level_data).to eq company_level_new_data
        end

        it 'should change the Pin status from in_progress to saved' do
          expect(Pin.last.status).to eq('saved')
        end
      end
    end

    it 'should raise exception if both pin and group are specified' do
      expect { cds_calculate_scores(-1, 1, 1, -1, -1) }.to raise_error('Ambiguous sub-group request with both pin-id and group-id')
    end
  end

  describe 'when metric_scores isn\'t empty' do
    before do
      # allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score }])
      allow_any_instance_of(Algorithm).to receive(:run).and_return([{ id: 1, measure: @mock_score }])
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      employee2
      cds_calculate_scores(1, -1, -1, -1, -1)
      @company1_scores = CdsMetricScore.where(company_id: 1).map(&:score)
    end

    it 'should keep data for other companies' do
      cds_calculate_scores(2, -1, -1, -1, -1)
      expect(CdsMetricScore.where(company_id: 1).map(&:score)).to eq @company1_scores
    end

    it 'should rewrite existing data for company' do
      res1 = CdsMetricScore.where(company_id: 1).length
      Group.destroy_all
      Pin.destroy_all
      cds_calculate_scores(1, -1, -1, -1, -1)
      res2 = CdsMetricScore.where(company_id: 1).length
      expect(res2).to be < res1
    end
  end

  describe 'when company is not specified' do
    before do
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      employee2
      allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score }])
      allow_any_instance_of(Algorithm).to receive(:run).and_return([{ id: 1, measure: @mock_score }])
    end

    describe ', when group is specified' do
      it 'should save data for the group' do
        cds_calculate_scores(-1, 1, -1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1)
        group1_data = CdsMetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(group1_data.select { |row| row[:algorithm_id] == mid }).to eq(company1_data.select { |row| row[:algorithm_id] == mid })
      end

      it 'should not save data on company level' do
        cds_calculate_scores(-1, 1, -1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
        expect(company1_data.empty?).to be true
      end
    end

    describe ', when pin is specified' do
      before do
        pin1
        EmployeesPin.create(pin_id: pin1[:id], employee_id: employee1[:id])
      end

      it 'should save data for the pin' do
        cds_calculate_scores(-1, -1, 1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1)
        pin1_data = CdsMetricScore.where(pin_id: 1)
        expect(company1_data.length).to be > 0
        expect(pin1_data.length).to eq(company1_data.length)
        mid = Algorithm.all.pluck(:id).to_a.sample
        expect(pin1_data.select { |row| row[:algorithm_id] == mid }).to eq(company1_data.select { |row| row[:algorithm_id] == mid })
      end

      it 'should not save data on company level' do
        cds_calculate_scores(-1, -1, 1, -1, -1)
        company1_data = CdsMetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
        expect(company1_data.empty?).to be true
      end
    end
  end

  describe 'when metric is specified' do
    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should save data only for the given metric' do
      mid = Algorithm.all.pluck(:id).to_a.sample
      cds_calculate_scores(1, -1, -1, mid, -1)
      all_data = CdsMetricScore.all
      metric_data = CdsMetricScore.where(algorithm_id: mid)
      expect(all_data.length).to eq metric_data.length
      expect(all_data.select { |row| row[:algorithm_id] == mid }).to eq all_data
    end

    it 'should throw exception if no such metric' do
      expect { cds_calculate_scores(-1, -1, -1, 9000, -1) }.to raise_error('No algorithms found!')
    end

    describe ', if data already exists' do
      before do
        cds_calculate_scores(1, -1, -1, -1, -1)
      end

      describe 'for measures' do
        before do
          @measure_id = @measure_ids.sample
          @measure_data = CdsMetricScore.all.select { |row| row[:algorithm_id] == @measure_id }
          @other_data = CdsMetricScore.all.select { |row| row[:algorithm_id] != @measure_id }
          allow_any_instance_of(Algorithm).to receive(:run).and_return([{ id: 1, measure: @mock_score / 2 }])
          cds_calculate_scores(1, -1, -1, @measure_id)
        end

        after do
          DatabaseCleaner.clean_with(:truncation)
          FactoryGirl.reload
        end

        it 'should rewrite data for given measure' do
          new_measure_data = CdsMetricScore.where(algorithm_id: @measure_id)
          expect(@measure_data.map(&:score)).to_not be eq(new_measure_data.map(&:score))
          expect(new_measure_data.map(&:score).sample).to eq(@mock_score / 2)
        end

        it 'should not change other metric data' do
          new_other_data = CdsMetricScore.all.select { |row| row[:algorithm_id] != @measure_id }
          expect(new_other_data.length).to eq @other_data.length
          expect(new_other_data.map(&:score)).to eq(@other_data.map(&:score))
        end
      end
    end
  end

  describe 'for snapshot' do
    describe ', if no company is specified' do
      describe ', if it\'s the last snapshot' do
        before do
          Snapshot.create(id: 2, company_id: 1, name: 'second')
        end

        it 'should precalculate all metric scores' do
          cds_calculate_scores(-1, -1, -1, -1, 2)
          expect(CdsMetricScore.all.length).to be > 1
        end

        it 'should precalculate data only for given snapshot' do
          cds_calculate_scores(-1, -1, -1, -1, 2)
          expect(CdsMetricScore.where(snapshot_id: 2).length).to eq CdsMetricScore.all.length
        end
      end

      describe 'if it\'s not the last snapshot' do
        before do
          Snapshot.create(id: 2, company_id: 1, name: 'second')
          cds_calculate_scores(-1, -1, -1, -1, -1)
          @old_measure_data_sample = CdsMetricScore.where(snapshot_id: 1, algorithm_id: 1, pin_id: nil, group_id: nil).first
          @old_flag_data = CdsMetricScore.where(snapshot_id: 1).select { |row| @flag_ids.include? row[:algorithm_id] }
          @old_analyze_data_sample = CdsMetricScore.where(snapshot_id: 1, algorithm_id: @analyze_ids[0]).first
          mock_all_besides_flags
          allow(ParamsToArgsHelper).to receive(:calculate_flags).and_return([])
        end

        it 'should rewrite historical analyze data' do
          old_score = CdsMetricScore.last[:score]
          cds_calculate_scores(-1, -1, -1, -1, 1)
          new_score = CdsMetricScore.last[:score]
          expect(old_score).to_not eq(new_score)
        end
      end
    end

    it 'should throw exception if snapshot doesn\'t belong to the specified company' do
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      expect { cds_calculate_scores(2, -1, -1, -1, 1) }.to raise_error
    end

    it 'should not throw exception if snapshot belongs to the specified company' do
      cds_calculate_scores(1, -1, -1, -1, 1)
      expect{CdsMetricScore.all.length}.not_to raise_error
    end
  end

  describe 'when \'rewrite\' flag is on' do
    before do
      Snapshot.create(id: 2, company_id: 1, name: 'second')
    end

    describe ', if old snapshot is chosen' do
      it 'should rewrite historical flag data' do
        cds_calculate_scores(-1, -1, -1, -1, 1, true)
        flag_data = CdsMetricScore.all.select { |row| @flag_ids.include? row[:algorithm_id] }
        expect(flag_data.length).to be > 0
      end

      it 'should rewrite historical analyze data' do
        cds_calculate_scores(-1, -1, -1, -1, 1, true)
        analyze_data = CdsMetricScore.all.select { |row| @analyze_ids.include? row[:algorithm_id] }
        expect(analyze_data.length).to be > 0
      end
    end

    describe ', if no snapshot specified' do
      it 'should save flag data for all snapshots' do
        cds_calculate_scores(-1, -1, -1, -1, -1, true)
        flag_data = CdsMetricScore.all.select { |row| @flag_ids.include? row[:algorithm_id] }
        expect(flag_data.map(&:snapshot_id)).to include 1
        expect(flag_data.map(&:snapshot_id)).to include 2
      end

      it 'should save analyze data for all snapshots' do
        cds_calculate_scores(-1, -1, -1, -1, -1, true)
        analyze_data = CdsMetricScore.all.select { |row| @analyze_ids.include? row[:algorithm_id] }
        expect(analyze_data.map(&:snapshot_id)).to include 1
        expect(analyze_data.map(&:snapshot_id)).to include 2
      end
    end
  end

  describe 'for group measures' do
    before do
      # FactoryGirl.create(:metric, name: 'Most Isolated Group', metric_type: 'group_measure', index: 0)
      @group_measures_ids = Algorithm.where(algorithm_type_id: 4).pluck(:id)
      group1.update(parent_group_id: 3)
      group2.update(parent_group_id: 3)
      group2

      # allow(self).to receive(:calculate_group_measure_scores).and_return([{ group_id: 1, measure: 1.0 }, { group_id: 2, measure: 0.0 }])
      allow_any_instance_of(Algorithm).to receive(:run).and_return([{ group_id: 1, measure: 1.0 }, { group_id: 2, measure: 0.0 }])
    end

    it 'should save measures for all groups in the company' do
      cds_calculate_scores(1, -1, -1, @group_measures_ids[0], -1)
      group_measure_data = CdsMetricScore.where(algorithm_id: @group_measures_ids[0])
      expect(group_measure_data.where(subgroup_id: 1).first[:score]).to eq 1.0
      expect(group_measure_data.where(subgroup_id: 2).first[:score]).to eq 0
    end

    it 'should write 0 to employee_id field' do
      cds_calculate_scores(1, -1, -1, @group_measures_ids[0], -1)
      group_measure_data = CdsMetricScore.where(algorithm_id: @group_measures_ids[0])
      expect(group_measure_data.sample[:employee_id]).to eq 0
    end
  end

  describe 'cds_calculate_z_scores' do
    before do
      AlgorithmType.create(id: 5, name: 'gauge')
      FactoryGirl.create(:algorithm, id: 101,  name: 'algo-101', algorithm_type_id: 5)
      FactoryGirl.create(:algorithm, id: 102,  name: 'algo-102', algorithm_type_id: 5)
      FactoryGirl.create(:algorithm, id: 103,  name: 'algo-103', algorithm_type_id: 5)
      (1..5).each do |i|
        (1..3).each do |j|
          CdsMetricScore.create!(group_id: i, algorithm_id: (100 + j), score: i, company_id: 1, snapshot_id: 1, company_metric_id: 1, employee_id: -1)
        end
      end
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should calculate correct z_scores' do
      cds_calculate_z_scores(1,1)
      scores = CdsMetricScore.where(algorithm_id: 101)
      expect( scores.first.z_score ).not_to be_nil
      expect( scores[2].z_score ).to be(0.0)
      expect( scores.first.z_score ).to be( scores.last.z_score * (-1) )
    end

    it 'should rewrite if rewrite=true' do
      CdsMetricScore.last.update(z_score: 1000.0)
      cds_calculate_z_scores(1, 1, true)
      expect( CdsMetricScore.last.z_score ).not_to be(1000.0)
    end

    it 'should not rewrite if rewrite=false' do
      CdsMetricScore.last.update(z_score: 1000.0)
      cds_calculate_z_scores(1, 1)
      expect( CdsMetricScore.last.z_score ).to be(1000.0)
    end
  end

  describe 'recalculate_score_for_central_and_negative_algorithms' do
    it 'should leave score same if both directions are the same' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0.5, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_HIGH_IS_GOOD)
      expect(new_score).to be(0.5)
    end

    it 'should flip score if one direction is high is good and the other is opposite ' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0.5, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_HIGH_IS_BAD)
      expect(new_score).to be(-0.5)
    end

    it 'when sone is central and parent is good should transform son so 0 becomes 1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(0, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be(1.0)
    end

    it 'when sone is central and parent is good should transform son so high scores become close to -1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(2, Algorithm::SCORE_SKEW_HIGH_IS_GOOD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be < -0.9
    end

    it 'when sone is central and parent is high is bad should transform son so low scores become close to -1' do
      new_score = recalculate_score_for_central_and_negative_algorithms(2, Algorithm::SCORE_SKEW_HIGH_IS_BAD, Algorithm::SCORE_SKEW_CENTRAL)
      expect(new_score).to be > 0.9
    end

    it 'when sone is central and parent is high is bad should transform son so 0 scores become close to 1' do
    end

  end

  describe 'cds_calculate_l3_scores' do
    before do
      DatabaseCleaner.clean_with(:truncation)
      Group.create!(id: 1, name: 'group-1', company_id: 1)
      Algorithm.create!(id: 1, name: 'L3',   algorithm_type_id: 6)
      Algorithm.create!(id: 2, name: 'L4-2', algorithm_type_id: 5)
      Algorithm.create!(id: 3, name: 'L4-3', algorithm_type_id: 5)

      ## Parent L3
      @gc = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm = CompanyMetric.create!(id: 1000, company_id: 1, algorithm_id: 1, gauge_id: @gc.id, algorithm_type_id: 1, network_id: -1)
      @ui = UiLevelConfiguration.create!(company_id: 1, level: 3, name: 'L3', company_metric_id: @cm.id, gauge_id: @gc.id)

      ## L4 Gauges
      @gc2 = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm2 = CompanyMetric.create!(id: 1001, company_id: 1, algorithm_id: 2, gauge_id: @gc2.id, algorithm_type_id: 5, network_id: -1)
      @ui2 = UiLevelConfiguration.create!(company_id: 1, level: 4, parent_id: @ui.id, name: 'L4-1', company_metric_id: @cm2.id, gauge_id: @gc2.id, weight: 0.6, display_order: 1)
      @score1 = 2
      CdsMetricScore.create!(company_id: 1, algorithm_id: 2, snapshot_id: 1, score: 1, z_score: @score1, employee_id: -1, group_id: 1, company_metric_id: @cm2.id)

      @gc3 = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm3 = CompanyMetric.create!(id: 1002, company_id: 1, algorithm_id: 3, gauge_id: @gc3.id, algorithm_type_id: 5, network_id: -1)
      @ui3 = UiLevelConfiguration.create!(company_id: 1, level: 4, parent_id: @ui.id, name: 'L4-2', company_metric_id: @cm3.id, gauge_id: @gc3.id, weight: 0.4, display_order: 2)
      @score2 = 1
      CdsMetricScore.create!(company_id: 1, algorithm_id: 3, snapshot_id: 1, score: 1, z_score: @score2, employee_id: -1, group_id: 1, company_metric_id: @cm3.id)
    end

    after do
      DatabaseCleaner.clean_with(:truncation)
      FactoryGirl.reload
    end

    it 'should work' do
      cds_calculate_l3_scores(1, 1)
      new_score = CdsMetricScore.last.score
      expect(new_score).to be < @score1
      expect(new_score).to be > @score2
    end

    it 'should return 0 if there are no l4 under it' do
      @ui2.delete
      @ui3.delete
      cds_calculate_l3_scores(1, 1)
      new_score = CdsMetricScore.last.score
      expect( new_score.to_f ).to be(0.0)
    end

    it 'result should be flipped if skew factor is opposite' do
      cds_calculate_l3_scores(1, 1)
      score = CdsMetricScore.last.score
      Algorithm.find(1).update(meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
      cds_calculate_l3_scores(1, 1)
      new_score = CdsMetricScore.last.score
      expect(score * (-1)).to eq(new_score)
    end
  end

  describe 'cds_calculate_l3_scores' do
    before do
      DatabaseCleaner.clean_with(:truncation)
      Group.create!(id: 1, name: 'group-1', company_id: 1)
      Algorithm.create!(id: 1, name: 'L3',              algorithm_type_id: 6)
      Algorithm.create!(id: 2, name: 'L4-2',            algorithm_type_id: 5)
      Algorithm.create!(id: 3, name: 'L4-flag-1',       algorithm_type_id: 2, comparrable_gauge_id: 4)
      Algorithm.create!(id: 4, name: 'L4-flag-gauge-1', algorithm_type_id: 5)
      Algorithm.create!(id: 5, name: 'L4-flag-2',       algorithm_type_id: 2, comparrable_gauge_id: 6)
      Algorithm.create!(id: 6, name: 'L4-flag-gauge-2', algorithm_type_id: 5)

      ## Parent L3
      @gc = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm = CompanyMetric.create!(id: 1000, company_id: 1, algorithm_id: 1, gauge_id: @gc.id, algorithm_type_id: 1, network_id: -1)
      @ui = UiLevelConfiguration.create!(company_id: 1, level: 3, name: 'L3', company_metric_id: @cm.id, gauge_id: @gc.id)

      ## L4 Gauges
      @gc2 = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm2 = CompanyMetric.create!(id: 1001, company_id: 1, algorithm_id: 2, gauge_id: @gc2.id, algorithm_type_id: 5, network_id: -1)
      @ui2 = UiLevelConfiguration.create!(company_id: 1, level: 4, parent_id: @ui.id, name: 'L4-1', company_metric_id: @cm2.id, gauge_id: @gc2.id, weight: 0.6, display_order: 1)
      @score1 = 2
      CdsMetricScore.create!(company_id: 1, algorithm_id: 2, snapshot_id: 1, score: 1, z_score: @score1, employee_id: -1, group_id: 1, company_metric_id: @cm2.id)

      @gc3 = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm3 = CompanyMetric.create!(id: 1002, company_id: 1, algorithm_id: 3, gauge_id: @gc3.id, algorithm_type_id: 2, network_id: -1)
      @ui3 = UiLevelConfiguration.create!(company_id: 1, level: 4, parent_id: @ui.id, name: 'L4-2', company_metric_id: @cm3.id, gauge_id: @gc3.id, weight: 0.4, display_order: 2)
      @cm4 = CompanyMetric.create!(id: 1003, company_id: 1, algorithm_id: 4, algorithm_type_id: 5, network_id: -1)

      @score2 = 1
      CdsMetricScore.create!(company_id: 1, algorithm_id: 3, snapshot_id: 1, score: 1, z_score: nil, employee_id: 1, group_id: 1, company_metric_id: @cm3.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 3, snapshot_id: 1, score: 0, z_score: nil, employee_id: 2, group_id: 1, company_metric_id: @cm3.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 4, snapshot_id: 1, score: 1, z_score: @score2, employee_id: -1, group_id: 1, company_metric_id: @cm4.id)
    end

    it 'shoud work with one flag' do
      cds_calculate_l3_scores(1, 1)
      new_score = CdsMetricScore.last.score
      expect(new_score).to be < @score1
      expect(new_score).to be > @score2
    end

    it 'shoud work with two flag' do
      @gc4 = GaugeConfiguration.create!(minimum_value: -1, maximum_value: -1, minimum_area: -1, maximum_area: -1, company_id: 1)
      @cm4 = CompanyMetric.create!(id: 1004, company_id: 1, algorithm_id: 5, gauge_id: @gc4.id, algorithm_type_id: 2, network_id: -1)
      @ui4 = UiLevelConfiguration.create!(company_id: 1, level: 4, parent_id: @ui.id, name: 'L4-3', company_metric_id: @cm4.id, gauge_id: @gc4.id, weight: 0.7, display_order: 3)
      @cm5 = CompanyMetric.create!(id: 1005, company_id: 1, algorithm_id: 6, algorithm_type_id: 5, network_id: -1)

      @score3 = 3
      CdsMetricScore.create!(company_id: 1, algorithm_id: 5, snapshot_id: 1, score: 1, z_score: nil, employee_id: 1, group_id: 1, company_metric_id: @cm4.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 5, snapshot_id: 1, score: 0, z_score: nil, employee_id: 2, group_id: 1, company_metric_id: @cm4.id)
      CdsMetricScore.create!(company_id: 1, algorithm_id: 6, snapshot_id: 1, score: 1, z_score: @score3, employee_id: -1, group_id: 1, company_metric_id: @cm5.id)
      @ui2.update(weight: 0.1)
      @ui3.update(weight: 0.2)

      cds_calculate_l3_scores(1, 1)
      new_score = CdsMetricScore.last.score
      pp new_score
      expect(new_score).to be < @score3
      expect(new_score).to be > @score2
    end
  end
end

describe 'InterAct' do
  before() do
    DatabaseCleaner.clean_with(:truncation)
    Company.create!(id: 1, name: 'testcom', randomize_image: true, active: true)
    snapshot_factory_create(id: 45, name: '2015-06', snapshot_type: 3, company_id: 2)
    Group.create!(id: 3, name: 'Testcom', company_id: 1, parent_group_id: nil)
    Group.create!(id: 4, name: 'QA',      company_id: 1, parent_group_id: 3)
    Employee.create!(id: 1, company_id: 1, email: 'pete1@sala.com', external_id: '11', first_name: 'Dave1', last_name: 'sala', group_id: 3)
    Employee.create!(id: 2, company_id: 1, email: 'pete2@sala.com', external_id: '12', first_name: 'Dave2', last_name: 'sala', group_id: 3)
    Employee.create!(id: 3, company_id: 1, email: 'pete3@sala.com', external_id: '13', first_name: 'Dave3', last_name: 'sala', group_id: 4)
    Employee.create!(id: 4, company_id: 1, email: 'pete4@sala.com', external_id: '14', first_name: 'Dave4', last_name: 'sala', group_id: 4)
    NetworkName.create!(id: 1, name: 'Advice', company_id: 1)
    NetworkName.create!(id: 2, name: 'Stam',   company_id: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 1, company_id: 1, from_employee_id: 3, to_employee_id: 4, value: 1)

    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 1, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 2, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 4, to_employee_id: 3, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 2, to_employee_id: 4, value: 1)
    NetworkSnapshotData.create!(snapshot_id: 45, network_id: 2, company_id: 1, from_employee_id: 1, to_employee_id: 3, value: 1)
  end

  describe 'save_generic_socre' do
    it 'should save score to database' do
      save_generic_socre(1, 45, 1, 3, 1, 88, 601, 5)
      expect( CdsMetricScore.count ).to eq(1)
      save_generic_socre(1, 45, 1, 3, 1, 89, 602, 2)
      expect( CdsMetricScore.count ).to eq(2)
    end
  end

  describe 'cds_calculate_scores_for_generic_network' do
    it 'should go over all results and save to db' do
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_indegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '2', 'score' => '3'}]
      )
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_outdegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '5', 'score' => '6'}]
      )
      cds_calculate_scores_for_generic_network(1, 45, 1, 3, 100, 101)
      expect( CdsMetricScore.count ).to eq(4)
    end
  end

  describe 'generate_company_metrics_for_network_out' do
    it 'should created a new company_metric if does not exist' do
      generate_company_metrics_for_network_out(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end

    it 'should created a new company_metric if does exist' do
      generate_company_metrics_for_network_out(1, 1)
      generate_company_metrics_for_network_out(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end
  end

  describe 'generate_company_metrics_for_network_in' do
    it 'should created a new company_metric if does not exist' do
      generate_company_metrics_for_network_in(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end

    it 'should created a new company_metric if does exist' do
      generate_company_metrics_for_network_in(1, 1)
      generate_company_metrics_for_network_in(1, 1)
      expect(CompanyMetric.count).to eq(1)
    end
  end

  describe 'cds_calculate_scores_for_generic_networks' do
    it 'should work' do
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_indegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '2', 'score' => '3'}]
      )
      allow(InteractAlgorithmsHelper).to receive(:calculate_network_outdegree).and_return(
        [{'employee_id' => '1', 'score': '2'}, {'employee_id' => '5', 'score' => '6'}]
      )
      cds_calculate_scores_for_generic_networks(1,45)
      expect( CdsMetricScore.count ).to eq(16)
    end
  end
end
