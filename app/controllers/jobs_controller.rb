class JobsController < ApplicationController
  include JobsHelper

  def jobs_status
    authorize :setting, :admin?

    ret = JobsHelper.jobs_status
    render json: ret, statatus: 200
  end
end
