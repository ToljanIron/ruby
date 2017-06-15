require './lib/tasks/modules/jobs_queue_helper.rb'
require './lib/tasks/modules/precalculate_metric_scores_helper.rb'
require './lib/tasks/modules/pre_calculate_pins_helper.rb'
require './app/helpers/jobs_helper.rb'
require './app/helpers/util_helper.rb'
include JobsHelper
include PreCalculatePinsHelper
include PrecalculateMetricScoresHelper
include UtilHelper
ERROR = 1
namespace :db do
  desc 'create_and_calculate_presets'
  task :create_and_calculate_presets, [:cid] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    t_id = ENV['ID'].to_i
    status = nil
    EventLog.log_event(job_id: t_id, message: 'create_and_calculate_preset statred')
    UtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      begin
        start_job(t_id) if t_id != 0
        company_id = args[:cid] || -1
        pins = find_pins(company_id)
        pins = pins.pre_create_pin
        pins.each do |pin|
          emps = get_employees(pin)
          unless save_employees_to_pin(pin, emps)
            finish_job_with_error(t_id) if t_id != 0
          end
          PrecalculateMetricScoresHelper::calculate_scores(company_id.to_i, -1, pin.id, -1, -1, true)
        end
        finish_job(t_id) if t_id != 0
        EventLog.log_event(job_id: t_id, message: 'create_and_calculate_preset ended')
      rescue => e
        finish_job_with_error(t_id) if t_id != 0
        status = ERROR
        raise ActiveRecord::Rollback
      end
    end
    EventLog.log_event(job_id: t_id, message: 'create_and_calculate_preset error') if status == ERROR
  end
end
