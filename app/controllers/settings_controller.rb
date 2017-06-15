include ExternalDataHelper
class SettingsController < ApplicationController
  def create_or_update_external_data
    authorize :setting, :index?
    cid = current_user.company_id
    res = save_external_data(JSON.parse(params[:data]), cid)
    render json: res
  end
end
