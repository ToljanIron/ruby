class QueuesPeeker
  def self.pick_at_queues
    puts "***********************************"
    puts "jobs\n----------------"
    Job.select(:id, :next_run, :name, :job_id).all.each do |j|
      puts "id: #{j.id},\tnext_run: #{j.next_run},\tname: #{j.name}"
    end

    puts "\njobs_queues\n----------------"
    JobsQueue.select(:id, :status, :job_id).all.each do |j|
      puts "id: #{j.id},\tjob_id: #{j.job_id},\tstatus: #{j.status}"
    end

    puts "\ndelayed_job\n----------------"
    Delayed::Job.select(:id, :handler).all.each do |j|
      puts "id: #{j.id},\thandler: #{j.handler}"
    end

    puts "\nScheduled_api_client_tasks\n----------------"
    ScheduledApiClientTask.select(:id, :status, :params).all.each do |j|
      puts "id: #{j.id},\tstatus: #{j.status},\tfrom_time: #{JSON.parse(ScheduledApiClientTask.last.params)['from_time']}"
    end

    puts "***********************************"
  end
end
