class OverlayEntityTypeController < ApplicationController
  def index
    authorize :measure, :index?
    cid = current_user.company_id
    type_ids = OverlayEntityConfiguration.where(company_id: cid, active: true).pluck(:overlay_entity_type_id)
    render json: OverlayEntityType.where(id: type_ids)
  end
end
