require 'spec_helper'
require './spec/spec_factory'
require './lib/tasks/modules/precalculate_metric_scores_helper.rb'
require './spec/factories/company_with_metrics_factory.rb'
require 'date'

include CompanyWithMetricsFactory

describe PrecalculateMetricScoresHelper, type: :helper do
  let(:group1) { FactoryGirl.create(:group, id: 1, company_id: 1, name: 'group1') }
  let(:group2) { FactoryGirl.create(:group, id: 2, company_id: 1, name: 'group2') }
  let(:pin1) { FactoryGirl.create(:pin, id: 1, company_id: 1, name: 'pin1') }
  let(:pin2) { FactoryGirl.create(:pin, id: 2, company_id: 1, name: 'pin2') }
  let(:employee1) { FactoryGirl.create(:group_employee, id: 1, company_id: 1, group_id: 1) }
  let(:employee3) { FactoryGirl.create(:group_employee, id: 3, company_id: 1, group_id: 2) }
  let(:employee2) { FactoryGirl.create(:employee, id: 2, company_id: 2, email: 'emp2@e.com', external_id: 2) }

  before do
    DatabaseCleaner.clean_with(:truncation)
    CompanyWithMetricsFactory.create_metrics
    Company.create(id: 1, name: 'company1')
    Snapshot.create(id: 1, company_id: 1, name: 'first')
    group1
    pin1
    EmployeesPin.create(pin_id: 1, employee_id: 1)
    employee1
    @measure_ids = Metric.where(metric_type: 'measure').map(&:id)
    @flag_ids = Metric.where(metric_type: 'flag').map(&:id)
    @analyze_ids = Metric.where(metric_type: 'analyze').map(&:id)
    @metrics_num = Metric.all.length
    @mock_score = 1.00


    allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score }])
    allow(self).to receive(:calculate_analyze_scores).and_return([{ id: 1, measure: @mock_score }])
    allow(self).to receive(:calculate_flags).and_return([{ id: 1 }])
  end

  after do
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.reload
  end

  describe 'for company with one employee and one snapshot' do
    describe ', when only company is specified' do
      before do
        calculate_scores(1, -1, -1, -1, -1)
        @company_data = MetricScore.where(company_id: 1)
      end

      describe 'measure scores' do
        before do
          @company_measure_data = @company_data.select { |row| @measure_ids.include?(row[:metric_id]) }
        end

        it 'should be saved for an employee on company level' do
          no_group_measure_data = @company_measure_data.select { |row| row[:group_id].nil? && row[:pin_id].nil? }
          expect(no_group_measure_data.length).to eq @measure_ids.length
        end

        it 'should be saved for an employee on group level' do
          group_measure_data = @company_measure_data.select { |row| row[:group_id] == employee1[:group_id] }
          expect(group_measure_data.length).to eq @measure_ids.length
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
          @company_flag_data = @company_data.select { |row| @flag_ids.include?(row[:metric_id]) }
        end

        it 'should be saved for an employee on company level' do
          no_group_flag_data = @company_flag_data.select { |row| row[:group_id].nil? && row[:pin_id].nil? }
          expect(no_group_flag_data.length).to eq @flag_ids.length
        end

        it 'should be saved for an employee on group level' do
          group_flag_data = @company_flag_data.select { |row| row[:group_id] == employee1[:group_id] }
          expect(group_flag_data.length).to eq @flag_ids.length
        end
      end

      it 'should throw exception if no such company' do
        expect { calculate_scores(9000, -1, -1, -1, -1) }.to raise_error
      end
    end

    describe 'when group id is specified' do
      before do
        group2
      end

      it 'should precalculate metric scores only for this group' do
        calculate_scores(1, 1, -1, -1, -1)
        company1_data = MetricScore.where(company_id: 1)
        group1_data = MetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(group1_data.select { |row| row[:metric_id] == mid }).to eq(company1_data.select { |row| row[:metric_id] == mid })
      end
      it 'should not change the Pins status' do
        calculate_scores(1, 1, -1, -1, -1)
        expect(Pin.first.status).to eq('pre_create_pin')
      end

      it 'should precalculate metric scores only for this group if company is not specified' do
        calculate_scores(-1, 1, -1, -1, -1)
        company1_data = MetricScore.where(company_id: 1)
        group1_data = MetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(group1_data.select { |row| row[:metric_id] == mid }).to eq(company1_data.select { |row| row[:metric_id] == mid })
      end

      it 'should throw exception if no such group' do
        expect { calculate_scores(-1, 9000, -1, -1, -1) }.to raise_error # it raises the error but returns nil also
        # expect ( calculate_scores(-1, 9000, -1, -1, -1) ).to be == nil
      end

      it 'should throw exception if no such group if company is specified' do
        expect { calculate_scores(1, 9000, -1, -1, -1) }.to raise_error
      end

      it 'should throw exception if the group doesn\'t belong to the company' do
        Company.create(id: 2, name: 'company2')
        Snapshot.create(id: 2, company_id: 2, name: 'second')
        expect { calculate_scores(2, 1, -1, -1, -1) }.to raise_error
      end

      describe ', when data already exists' do
        before do
          employee3
          calculate_scores(1, -1, -1, -1, -1)
          @measure_group_data_before = MetricScore.where(group_id: 1).select { |row| @measure_ids.include? row[:metric_id] }
          @flag_group_data_before = MetricScore.where(group_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
          @group2_data = MetricScore.where(group_id: 2)
          @pin1_data = MetricScore.where(pin_id: 1)
          @company_level_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          # mocking changes in data
          allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
          allow(self).to receive(:calculate_flags).and_return([])
          # recalculating for group 1
          calculate_scores(1, 1, -1, -1, -1)
        end

        it 'should rewrite group measure data if it exists' do
          group_data = MetricScore.where(group_id: 1).select { |row| @measure_ids.include? row[:metric_id] }
          # check that it consists only of the data for employees in the group
          expect(group_data.select { |row| row[:score] == @mock_score / 2 }).to eq group_data
        end

        it 'should rewrite group flag data if it exists' do
          group_data = MetricScore.where(group_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
          # check that it consists only of the data for employees in the group
          expect(group_data.empty?).to be true
        end

        it 'should leave other groups data unchanged' do
          group2_new_data = MetricScore.where(group_id: 2)
          expect(@group2_data).to eq group2_new_data
        end

        it 'should leave other pins data unchanged' do
          pin1_new_data = MetricScore.where(pin_id: 1)
          expect(@pin1_data).to eq pin1_new_data
        end

        it 'should leave company level data unchanged' do
          company_level_new_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          expect(@company_level_data).to eq company_level_new_data
        end
      end
    end

    describe 'when pin id is specified' do
      it 'should precalculate metric scores only for given pin' do
        calculate_scores(1, -1, 1, -1, -1)
        all_data = MetricScore.all
        pin_data = MetricScore.where(pin_id: pin1.id)
        expect(all_data.length).to be > 0
        expect(all_data.length).to eq(pin_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(all_data.select { |row| row[:metric_id] == mid }.first).to eq(pin_data.select { |row| row[:metric_id] == mid }.first)
      end

      it 'should precalculate metric scores only for given pin if company is not specified' do
        calculate_scores(-1, -1, 1, -1, -1)
        all_data = MetricScore.all
        pin_data = MetricScore.where(pin_id: pin1.id)
        expect(all_data.length).to be > 0
        expect(all_data.length).to eq(pin_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(all_data.select { |row| row[:metric_id] == mid }.first).to eq(pin_data.select { |row| row[:metric_id] == mid }.first)
      end

      it 'should throw exception if no such pin' do
        expect { calculate_scores(-1, -1, 9000, -1, -1) }.to raise_error
      end

      it 'should throw exception if no such pin if company is specified' do
        expect { calculate_scores(1, -1, 9000, -1, -1) }.to raise_error
      end

      it 'should throw exception if the group doesn\'t belong to the company' do
        Company.create(id: 2, name: 'company2')
        Snapshot.create(id: 2, company_id: 2, name: 'second')
        expect { calculate_scores(2, -1, 1, -1, -1) }.to raise_error
      end

      describe ', when data already exists' do
        before do
          pin2
          EmployeesPin.create(pin_id: 2, employee_id: 1)
          calculate_scores(1, -1, -1, -1, -1)
          @measure_pin_data_before = MetricScore.where(pin_id: 1).select { |row| @measure_ids.include? row[:metric_id] }
          @flag_pin_data_before = MetricScore.where(pin_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
          @group_data = MetricScore.where(group_id: 1)
          @pin2_data = MetricScore.where(pin_id: 2)
          @company_level_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
          # mocking changes in data
          allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
          allow(self).to receive(:calculate_flags).and_return([])
          # recalculating for group 1
          calculate_scores(1, -1, 1, -1, -1)
        end

        it 'should rewrite pin measure data' do
          pin_data = MetricScore.where(pin_id: 1).select { |row| @measure_ids.include? row[:metric_id] }
          # check that it consists only of the data for employees in the group
          expect(pin_data.select { |row| row[:score] == @mock_score / 2 }).to eq pin_data
        end

        it 'should rewrite pin flag data' do
          pin_data = MetricScore.where(pin_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
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
      expect { calculate_scores(-1, 1, 1, -1, -1) }.to raise_error
    end
  end

  describe 'when metric_scores isn\'t empty' do
    before do
      allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score }])
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      employee2
      calculate_scores(1, -1, -1, -1, -1)
      @company1_scores = MetricScore.where(company_id: 1).map(&:score)
    end

    it 'should keep data for other companies' do
      calculate_scores(2, -1, -1, -1, -1)
      expect(MetricScore.where(company_id: 1).map(&:score)).to eq @company1_scores
    end

    it 'should rewrite existing data for company' do
      # before changing the company
      expect(MetricScore.where(company_id: 1).length).to eq(Metric.all.length * 3) # company, group, pin
      Group.destroy_all
      Pin.destroy_all
      calculate_scores(1, -1, -1, -1, -1)
      # after changing the company
      expect(MetricScore.where(company_id: 1).length).to eq(Metric.all.length)
    end
  end

  describe 'when company is not specified' do
    before do
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      employee2
      allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score }])
    end

    it 'should save data for all companies' do
      calculate_scores(-1, -1, -1, -1, -1)
      company1_data = MetricScore.where(company_id: 1)
      company2_data = MetricScore.where(company_id: 2)
      expect(company1_data.length).to be > 0
      expect(company2_data.length).to be > 0
    end

    describe ', when group is specified' do
      it 'should save data for the group' do
        calculate_scores(-1, 1, -1, -1, -1)
        company1_data = MetricScore.where(company_id: 1)
        group1_data = MetricScore.where(group_id: 1)
        expect(company1_data.length).to be > 0
        expect(group1_data.length).to eq(company1_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(group1_data.select { |row| row[:metric_id] == mid }).to eq(company1_data.select { |row| row[:metric_id] == mid })
      end

      it 'should not save data on company level' do
        calculate_scores(-1, 1, -1, -1, -1)
        company1_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
        expect(company1_data.empty?).to be true
      end
    end

    describe ', when pin is specified' do
      before do
        pin1
        EmployeesPin.create(pin_id: pin1[:id], employee_id: employee1[:id])
      end

      it 'should save data for the pin' do
        calculate_scores(-1, -1, 1, -1, -1)
        company1_data = MetricScore.where(company_id: 1)
        pin1_data = MetricScore.where(pin_id: 1)
        expect(company1_data.length).to be > 0
        expect(pin1_data.length).to eq(company1_data.length)
        mid = (1..@metrics_num).to_a.sample
        expect(pin1_data.select { |row| row[:metric_id] == mid }).to eq(company1_data.select { |row| row[:metric_id] == mid })
      end

      it 'should not save data on company level' do
        calculate_scores(-1, -1, 1, -1, -1)
        company1_data = MetricScore.where(company_id: 1, group_id: nil, pin_id: nil)
        expect(company1_data.empty?).to be true
      end
    end
  end

  describe 'when metric is specified' do
    it 'should save data only for the given metric' do
      mid = (1..@metrics_num).to_a.sample
      calculate_scores(1, -1, -1, mid, -1)
      all_data = MetricScore.all
      metric_data = MetricScore.where(metric_id: mid)
      expect(all_data.length).to eq metric_data.length
      expect(all_data.select { |row| row[:metric_id] == mid }).to eq all_data
    end

    it 'should save data for the metric if company isn\'t specified' do
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      employee2
      mid = (1..@metrics_num).to_a.sample
      calculate_scores(-1, -1, -1, mid, -1)
      all_data = MetricScore.all
      metric_data = MetricScore.where(metric_id: mid)
      expect(all_data.length).to eq metric_data.length
      expect(all_data.map(&:company_id)).to include 1
      expect(all_data.map(&:company_id)).to include 2
      expect(all_data.select { |row| row[:metric_id] == mid }).to eq all_data.to_a
    end

    it 'should throw exception if no such metric' do
      expect { calculate_scores(-1, -1, -1, 9000, -1) }.to raise_error
    end

    describe ', if data already exists' do
      before do
        calculate_scores(1, -1, -1, -1, -1)
      end

      describe 'for measures' do
        before do
          @measure_id = (1..@measure_ids.length).to_a.sample
          @measure_data = MetricScore.all.select { |row| row[:metric_id] == @measure_id }
          @other_data = MetricScore.all.select { |row| row[:metric_id] != @measure_id }
          # mocking changes in data
          allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
          calculate_scores(1, -1, -1, @measure_id)
        end

        it 'should rewrite data for given measure' do
          new_measure_data = MetricScore.where(metric_id: @measure_id)
          expect(@measure_data.map(&:score)).to_not be eq(new_measure_data.map(&:score))
          expect(new_measure_data.map(&:score).sample).to eq(@mock_score / 2)
        end

        it 'should not change other metric data' do
          new_other_data = MetricScore.all.select { |row| row[:metric_id] != @measure_id }
          expect(new_other_data.length).to eq @other_data.length
          expect(new_other_data.map(&:score)).to eq(@other_data.map(&:score))
        end
      end

      describe 'for flags' do
        before do
          @flag_id = (1..@flag_ids.length).to_a.sample + @measure_ids.length
          @flag_data = MetricScore.all.select { |row| row[:metric_id] == @flag_id }
          @other_data = MetricScore.all.select { |row| row[:metric_id] != @flag_id }
          # mocking changes in data
          allow(self).to receive(:calculate_flags).and_return([{ id: 0 }])
          calculate_scores(1, -1, -1, @flag_id)
        end

        it 'should rewrite data for given flag' do
          new_flag_data = MetricScore.where(metric_id: @flag_id)
          expect(@flag_data.map(&:score)).to_not be eq(new_flag_data.map(&:score))
          expect(new_flag_data.map(&:employee_id).sample).to eq(0)
        end

        it 'should not change other metrics' do
          new_other_data = MetricScore.all.select { |row| row[:metric_id] != @flag_id }
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
          calculate_scores(-1, -1, -1, -1, 2)
          expect(MetricScore.all.length).to eq(@metrics_num * 3) # company, group, pin
        end

        it 'should precalculate data only for given snapshot' do
          calculate_scores(-1, -1, -1, -1, 2)
          expect(MetricScore.where(snapshot_id: 2).length).to eq MetricScore.all.length
        end
      end

      describe 'if it\'s not the last snapshot' do
        before do
          Snapshot.create(id: 2, company_id: 1, name: 'second')
          calculate_scores(-1, -1, -1, -1, -1)
          @old_measure_data_sample = MetricScore.where(snapshot_id: 1, metric_id: 1, pin_id: nil, group_id: nil).first
          @old_flag_data = MetricScore.where(snapshot_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
          @old_analyze_data_sample = MetricScore.where(snapshot_id: 1, metric_id: @analyze_ids[0]).first
          allow(self).to receive(:calculate_measure_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
          allow(self).to receive(:calculate_flags).and_return([])
          allow(self).to receive(:calculate_analyze_scores).and_return([{ id: 1, measure: @mock_score / 2 }])
        end

        it 'should rewrite historical measure scores' do
          calculate_scores(-1, -1, -1, -1, 1)
          changed_data_sample = MetricScore.where(snapshot_id: 1, metric_id: 1, pin_id: nil, group_id: nil).first
          expect(changed_data_sample[:score]).to_not eq(@old_measure_data_sample[:score])
        end

        it 'should not change flag data' do
          calculate_scores(-1, -1, -1, -1, 1)
          un_changed_data = MetricScore.where(snapshot_id: 1).select { |row| @flag_ids.include? row[:metric_id] }
          expect(un_changed_data).to eq @old_flag_data
        end

        it 'should rewrite historical analyze data' do
          calculate_scores(-1, -1, -1, -1, 1)
          changed_data_sample = MetricScore.where(snapshot_id: 1, metric_id: @analyze_ids[0]).first
          expect(changed_data_sample[:score]).to_not eq(@old_analyze_data_sample[:score])
        end

        describe ', when specific metric is chosen' do
          it 'should rewrite historical data if it\'s a measure' do
            calculate_scores(-1, -1, -1, 1, 1)
            changed_data_sample = MetricScore.where(snapshot_id: 1, metric_id: 1, pin_id: nil, group_id: nil).first
            expect(changed_data_sample[:score]).to_not eq(@old_measure_data_sample[:score])
          end
        end
      end
    end

    it 'should throw exception if snapshot doesn\'t belong to the specified company' do
      Company.create(id: 2, name: 'company2')
      Snapshot.create(id: 2, company_id: 2, name: 'second')
      expect { calculate_scores(2, -1, -1, -1, 1) }.to raise_error
    end

    it 'should not throw exception if snapshot belongs to the specified company' do
      calculate_scores(1, -1, -1, -1, 1)
      expect(MetricScore.all.length).to eq(@metrics_num * 3)
    end
  end

  describe 'when \'rewrite\' flag is on' do
    before do
      Snapshot.create(id: 2, company_id: 1, name: 'second')
    end

    describe ', if old snapshot is chosen' do
      it 'should rewrite historical flag data' do
        calculate_scores(-1, -1, -1, -1, 1, true)
        flag_data = MetricScore.all.select { |row| @flag_ids.include? row[:metric_id] }
        expect(flag_data.length).to be > 0
      end

      it 'should rewrite historical analyze data' do
        calculate_scores(-1, -1, -1, -1, 1, true)
        analyze_data = MetricScore.all.select { |row| @analyze_ids.include? row[:metric_id] }
        expect(analyze_data.length).to be > 0
      end
    end

    describe ', if no snapshot specified' do
      it 'should save flag data for all snapshots' do
        calculate_scores(-1, -1, -1, -1, -1, true)
        flag_data = MetricScore.all.select { |row| @flag_ids.include? row[:metric_id] }
        expect(flag_data.map(&:snapshot_id)).to include 1
        expect(flag_data.map(&:snapshot_id)).to include 2
      end

      it 'should save analyze data for all snapshots' do
        calculate_scores(-1, -1, -1, -1, -1, true)
        analyze_data = MetricScore.all.select { |row| @analyze_ids.include? row[:metric_id] }
        expect(analyze_data.map(&:snapshot_id)).to include 1
        expect(analyze_data.map(&:snapshot_id)).to include 2
      end
    end
  end

  describe 'for group measures' do
    before do
      FactoryGirl.create(:metric, name: 'Most Isolated Group', metric_type: 'group_measure', index: 0)
      @group_measures_ids = Metric.where(metric_type: 'group_measure').pluck(:id)
      # group1.update(parent_group_id: 3)
      # group2.update(parent_group_id: 3)
      group2
      allow(self).to receive(:calculate_group_measure_scores).and_return([{ group_id: 1, measure: 1.0 }, { group_id: 2, measure: 0.0 }])
    end

    it 'should save measures for all groups in the company' do
      calculate_scores(1, -1, -1, @group_measures_ids[0], -1)
      group_measure_data = MetricScore.where(metric_id: @group_measures_ids[0])
      expect(group_measure_data.where(subgroup_id: 1).first[:score]).to eq 1.0
      expect(group_measure_data.where(subgroup_id: 2).first[:score]).to eq 0
    end

    it 'should write 0 to employee_id field' do
      calculate_scores(1, -1, -1, @group_measures_ids[0], -1)
      group_measure_data = MetricScore.where(metric_id: @group_measures_ids[0])
      expect(group_measure_data.sample[:employee_id]).to eq 0
    end

    it 'should write only one record for each group per measure and snapshot and per parent group + company level' do
      calculate_scores(1, -1, -1, @group_measures_ids[0], -1)
      group_measure_data = MetricScore.where(metric_id: @group_measures_ids[0])
      expect(group_measure_data.length).to eq 6
    end
  end
end
