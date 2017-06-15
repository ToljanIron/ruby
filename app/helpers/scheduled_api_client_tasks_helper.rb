module ScheduledApiClientTasksHelper
  def vaild_api_client_task?(id)
    return ApiClientTaskDefinition.find(id)
  rescue
    return false
  end

  def vaild_jobs_queue?(id)
    return JobsQueue.find(id)
  rescue
    return false
  end

  def valid_client?(id)
    return ApiClient.find(id)
  rescue
    return false
  end
end
