class OverlaySnapshotDataController < ApplicationController
  def show
    authorize :measure, :index?
    cid = current_user.company_id
    oegid = JSON.parse(params[:oegid]).try(:to_a)
    ids = JSON.parse(params[:ids]).try(:to_a)
    sid = params[:snapshot_id].try(:to_i)
    gid = params[:gid].try(:to_i)
    data = cache_read("overlay-snapshot-data-#{cid}-#{gid}-#{oegid.try(:join, ',')}-#{sid}")
    if data.nil?
      type_ids = OverlayEntityConfiguration.where(company_id: cid, active: true).pluck(:overlay_entity_type_id)
      data = if type_ids.empty?
               {
                 overlay_entities: [],
                 network: [],
                 overlay_entity_groups: [],
                 overlay_entity_types: []
               }
             else
               overlay_entities = OverlayEntity.pick_by_group(oegid, ids, cid, type_ids)
               network = OverlaySnapshotData.pick_by_group(cid, oegid, ids, gid, type_ids, sid)
               # OverlayEntityGroup.sorted_of_types(type_ids, cid)
               overlay_entity_groups = oegid ? OverlayEntityGroup.where(id: oegid) : []
               overlay_entity_types = OverlayEntityType.where(id: type_ids)
               {
                 overlay_entities: overlay_entities,
                 network: network,
                 overlay_entity_groups: overlay_entity_groups,
                 overlay_entity_types: overlay_entity_types
               }
             end
      cache_write("overlay-snapshot-data-#{cid}-#{gid}-#{oegid}-#{sid}", data)
    end
    render json: Oj.dump(data)
  end

  def show_keywords
    authorize :measure, :index?
    cid = current_user.company_id
    cachekey = "get_keywords-#{cid}"
    data     = cache_read(cachekey)
    if data.nil?
      data = OverlayEntity.get_keywords(cid)
      cache_write(cachekey, data)
    end
    render json: data
  end
end
