EventType.delete_all
EventType.create!(id: 1  , name: 'GENERAL_EVENT') unless EventType.find_by(name: 'GENERAL_EVENT')
EventType.create!(id: 2  , name: 'JOB_STARTED') unless EventType.find_by(name: 'JOB_STARTED')
EventType.create!(id: 3  , name: 'JOB_DONE') unless EventType.find_by(name: 'JOB_DONE')
EventType.create!(id: 4  , name: 'JOB_KILLED_ERR_DID_NOT_RUN') unless EventType.find_by(name: 'JOB_KILLED_ERR_DID_NOT_RUN')
EventType.create!(id: 5  , name: 'JOB_KILLED_ERR_DID_NOT_FINISH') unless EventType.find_by(name: 'JOB_KILLED_ERR_DID_NOT_FINISH')
EventType.create!(id: 6  , name: 'JOB_ARCHIVED') unless EventType.find_by(name: 'JOB_ARCHIVED')
EventType.create!(id: 7  , name: 'JOB_FAIL') unless EventType.find_by(name: 'JOB_FAIL')
EventType.create!(id: 8  , name: 'JOB_ARCHIVED') unless EventType.find_by(name: 'JOB_ARCHIVED')
EventType.create!(id: 9  , name: 'SCHEDULE_CLIENT_JOB') unless EventType.find_by(name: 'SCHEDULE_CLIENT_JOB')
EventType.create!(id: 10  , name: 'ARCHIVE_OLD_JOBS_QUEUES') unless EventType.find_by(name: 'ARCHIVE_OLD_JOBS_QUEUES')
EventType.create!(id: 11  , name: 'SCHEDULE_JOB') unless EventType.find_by(name: 'SCHEDULE_JOB')
EventType.create!(id: 12  , name: 'ERROR') unless EventType.find_by(name: 'ERROR')
EventType.create!(id: 13  , name: 'FATAL') unless EventType.find_by(name: 'FATAL')
EventType.create!(id: 14  , name: 'WARN') unless EventType.find_by(name: 'WARN')
EventType.create!(id: 15  , name: 'INFO') unless EventType.find_by(name: 'INFO')
EventType.create!(id: 16  , name: 'QUESTIONNAIRE') unless EventType.find_by(name: 'QUESTIONNAIRE')
EventType.create!(id: 17  , name: 'LOGIN') unless EventType.find_by(name: 'LOGIN')
EventType.create!(id: 18  , name: 'COLLECTOR') unless EventType.find_by(name: 'COLLECTOR')
