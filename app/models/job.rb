# frozen_string_literal: true

class Job < ActiveRecord::Base

  EVENT_ID_PROCESS_UPDATES=19

  belongs_to :company
  has_many :job_stage

  enum status: [
    :ready,
    :in_progress,
    :wait_for_retry,
    :done,
    :error
  ]

  def create_stage(_domain_id, p=nil)
    p ||= {}
    ps = JobStage.create!(
      domain_id: _domain_id,
      job_id: id,
      company_id: company_id,
      stage_type: (p[:stage_type].nil? ? job_type : p[:stage_type]),
      value: (p[:value].nil? ? 1 : p[:value]),
      stage_order: (p[:order].nil? ? id : p[:order])
    )
    return ps
  end

  def get_next_stage
    stage = JobStage.where(status: :error).order(:stage_order).first
    return stage if !stage.nil?
    stage = JobStage.where(status: :ready).order(:stage_order).first
    return stage
  end

  def start
    raise "Job: #{id} cannot start from status: #{status}" if status != 'ready'
    Job.transaction do
      update!(status: :in_progress,
              run_start_at: Time.now)
      logevent("Started")
    end
  end

  def finish_successfully
    Job.transaction do
      update!(status: :done,
              run_end_at: Time.now)
      logevent("Finished successfully")
    end
  end

  def finish_with_error(error_msg, retrie=true)
    Job.transaction do
      if retrie == false || number_of_retries >= max_number_of_retries
        update!(status: :error,
                error_message: error_msg,
                run_end_at: Time.now)
        logevent("Finished with error: #{error_msg}")
      else
        update!(status: :wait_for_retry,
                error_message: error_msg,
                run_end_at: Time.now)
        logevent("Try number #{number_of_retries} finished with error: #{error_msg}")
      end
    end
  end

  def retry
    raise "Job: #{id} cannot retry from status: #{status}" if status != 'wait_for_retry'
    Job.transaction do
      update!(status: :in_progress,
              number_of_retries: number_of_retries + 1,
              run_start_at: Time.now)
      logevent("Try number #{number_of_retries} start")
    end
  end

  private

  def logevent(msg)
    EventLog.create!(
      message: "Job: #{id} - msg",
      event_type_id: EVENT_ID_PROCESS_UPDATES
    )
  end

end
