module TestEventTypeSeed
  def self.run_seed
    event_types
  end

  def self.event_types
    EventType.create!(name: 'GENERAL_EVENT') unless EventType.find_by(name: 'GENERAL_EVENT')
    EventType.create!(name: 'JOB_STARTED') unless EventType.find_by(name: 'JOB_STARTED')
    EventType.create!(name: 'JOB_DONE') unless EventType.find_by(name: 'JOB_DONE')
    EventType.create!(name: 'JOB_KILLED_ERR_DID_NOT_RUN') unless EventType.find_by(name: 'JOB_KILLED_ERR_DID_NOT_RUN')
    EventType.create!(name: 'JOB_KILLED_ERR_DID_NOT_FINISH') unless EventType.find_by(name: 'JOB_KILLED_ERR_DID_NOT_FINISH')
    EventType.create!(name: 'JOB_ARCHIVED') unless EventType.find_by(name: 'JOB_ARCHIVED')
    EventType.create!(name: 'JOB_FAIL') unless EventType.find_by(name: 'JOB_FAIL')
    EventType.create!(name: 'JOB_ARCHIVED') unless EventType.find_by(name: 'JOB_ARCHIVED')
    EventType.create!(name: 'SCHEDULE_CLIENT_JOB') unless EventType.find_by(name: 'SCHEDULE_CLIENT_JOB')
    EventType.create!(name: 'ARCHIVE_OLD_JOBS_QUEUES') unless EventType.find_by(name: 'ARCHIVE_OLD_JOBS_QUEUES')
    EventType.create!(name: 'SCHEDULE_JOB') unless EventType.find_by(name: 'SCHEDULE_JOB')
    EventType.create!(name: 'ERROR') unless EventType.find_by(name: 'ERROR')
    EventType.create!(name: 'FATAL') unless EventType.find_by(name: 'FATAL')
    EventType.create!(name: 'WARN') unless EventType.find_by(name: 'WARN')
    EventType.create!(name: 'INFO') unless EventType.find_by(name: 'INFO')
    EventType.create!(name: 'QUESTIONNAIRE') unless EventType.find_by(name: 'QUESTIONNAIRE')
  end
end

TestEventTypeSeed.run_seed
