# frozen_string_literal: true

class JobStage < ActiveRecord::Base

  EVENT_ID_JOB_UPDATES=19

  belongs_to :job

  enum status: [
    :ready,
    :running,
    :done,
    :error
  ]

  def start
    JobStage.transaction do
      update!(status: :running,
              run_start_at: Time.now)
      logevent("Started")
    end
  end

  def finish_successfully(_value)
    JobStage.transaction do
      update!(status: :done,
              run_end_at: Time.now,
              value: (_value.nil? ? value : _value))
      logevent("Finished successfully")
    end
  end

  def finish_with_error(error_msg)
    JobStage.transaction do
      update!(status: :error,
              error_message: error_msg,
              run_end_at: Time.now)
      logevent("Finished with error: #{error_msg}")
    end
  end

  private

  def logevent(msg)
    EventLog.create!(
      message: "JobStage: #{id} - msg",
      event_type_id: EVENT_ID_JOB_UPDATES
    )
  end

end
