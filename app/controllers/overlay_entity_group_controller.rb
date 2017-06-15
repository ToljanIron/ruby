class OverlayEntityGroupController < ApplicationController
  def show
    authorize :measure, :index?
    cid = current_user.company_id
    data = cache_read("overlay-entity-group-#{cid}}")
    if data.nil?
      type_ids = OverlayEntityConfiguration.where(company_id: cid, active: true).pluck(:overlay_entity_type_id)
      data = []
      data = OverlayEntityGroup.sorted_of_types(type_ids, cid) unless type_ids.empty?
      cache_write("overlay-entity-group-#{cid}", data)
    end
    render json: Oj.dump(data)
  end
end
