require './app/helpers/report_helper.rb'

REPORT_TYPE_GROUPS_GAUGE_REGRESSION   = 'group_gauge_regression'
REPORT_TYPE_EMPLOYEE_SCORE_REGRESSION = 'employee_scores_report'
REPORT_TYPE_GROUPS_MATRIX_REGRESSION  = 'group_regression_matrix'
REPORT_TYPE_INTERACT                  = 'interact_report'
REPORT_TYPE_EMPLOYEE_SCORES           = 'employee_scores'
REPORT_TYPE_QUESTIONNAIRE_COMPLETION_STATUS = 'questionnaire_completion_status'
REPORT_TYPE_EMAILS_DUMP               = 'emails_dump'

namespace :db do
  desc 'create_scores_report'
  task :create_scores_report, [:cid, :type] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    cid   = args[:cid]  || ENV['COMPANY_ID'] || (fail 'No company ID given (cid)')
    type  = args[:type] || (fail "No report type given")

    if type != REPORT_TYPE_GROUPS_GAUGE_REGRESSION &&
       type != REPORT_TYPE_EMPLOYEE_SCORE_REGRESSION &&
       type != REPORT_TYPE_INTERACT &&
       type != REPORT_TYPE_EMPLOYEE_SCORES &&
       type != REPORT_TYPE_QUESTIONNAIRE_COMPLETION_STATUS &&
       type != REPORT_TYPE_EMAILS_DUMP &&
       type != REPORT_TYPE_GROUPS_MATRIX_REGRESSION
      fail
        "Type: #{type} is illegal, use one of:
          - #{REPORT_TYPE_EMPLOYEE_SCORE_REGRESSION} or
          - #{REPORT_TYPE_GROUPS_GAUGE_REGRESSION} or
          - #{REPORT_TYPE_INTERACT} or
          - #{REPORT_TYPE_EMPLOYEE_SCORES} or
          - #{REPORT_TYPE_EMAILS_DUMP} or
          - #{REPORT_TYPE_GROUPS_MATRIX_REGRESSION}"
    end
    puts "Running report of type: #{type} with CID=#{cid}"

    UtilHelper.cache_delete_all
    ActiveRecord::Base.transaction do
      begin
        ReportHelper::create_gauge_regression_report(cid) if type == REPORT_TYPE_GROUPS_GAUGE_REGRESSION
        ReportHelper::create_employees_report(cid)        if type == REPORT_TYPE_EMPLOYEE_SCORE_REGRESSION
        puts ReportHelper::prepare_regression_report_in_matrix_format(cid) if type == REPORT_TYPE_GROUPS_MATRIX_REGRESSION
        puts ReportHelper::create_interact_report(cid) if type == REPORT_TYPE_INTERACT
        puts ReportHelper::simple_employee_scores_report(cid) if type == REPORT_TYPE_EMPLOYEE_SCORES
        puts ReportHelper::questionnaire_completion_status(cid) if type == REPORT_TYPE_QUESTIONNAIRE_COMPLETION_STATUS
        ReportHelper::emails_dump(cid) if type == REPORT_TYPE_EMAILS_DUMP
      rescue => e
        error = e.message
        puts "got exception: #{error}"
        puts e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
