class OverlayEntity < ActiveRecord::Base
  belongs_to :overlay_entity_type
  belongs_to :overlay_entity_group

  def connections_from
    OverlaySnapshotData.where(from_type: 'from_overlay_entity', from_id: id)
  end

  def connections_to
    OverlaySnapshotData.where(to_type: 'to_overlay_entity', to_id: id)
  end

  def connections
    connections_from + connections_to
  end

  def self.pick_by_group(gid, ids, cid, type_ids)
    choose_part = if gid && !gid.empty?
                    if ids && !ids.empty?
                      "and (oe.overlay_entity_group_id in (#{gid.join(',')}) or oe.id in (#{ids.join(',')}))"
                    else
                      "and oe.overlay_entity_group_id in (#{gid.join(',')})"
                    end
                  elsif ids && !ids.empty?
                    "and oe.id in (#{ids.join(',')})"
                  else
                    ''
                  end
    res = ActiveRecord::Base.connection.select_all(
      "select oe.*, colors.rgb as color, oeg.image_url, oeg.name as overlay_entity_group_name,
                oet.name as overlay_entity_type_name, 1 as rate, 'overlay_entity' as node_type
       from overlay_entities as oe
       left join overlay_entity_groups as oeg on oeg.id = oe.overlay_entity_group_id
       left join overlay_entity_types as oet on oet.id = oe.overlay_entity_type_id
       left join colors on oet.color_id = colors.id
       where
       oe.company_id = #{cid} and
       oe.active = 'true' and oe.overlay_entity_type_id in (#{type_ids.join(',')}) " +
       choose_part).to_json
    res = JSON.parse(res)
    res.each do |obj|
      obj['id'] = obj['id'].to_i
      obj['color'] = '#' + obj['color'] if obj['color']
    end
    return res
    # return OverlayEntity.all unless gid
    # OverlayEntity.where(overlay_entity_group_id: gid)
  end

  def self.get_keywords(cid, emps = nil, sid = nil)
    from_emps_str = emps.nil? ? '' : "osd.from_id in(#{emps.join(',')}) and"
    to_emps_str   = emps.nil? ? '' : "osd.to_id   in(#{emps.join(',')}) and"
    sid_str       = sid.nil?  ? '' : "snapshot_id = #{sid} and"
    sqlstr = " select id, name, overlay_entity_type_id, overlay_entity_group_id, sum(connections) as num from
      (select oe.id as id, oe.name as name, overlay_entity_type_id, overlay_entity_group_id, osd.from_id as kid, osd.value as connections
        from overlay_snapshot_data as osd
        join overlay_entities as oe on osd.from_id = oe.id
        where
        oe.overlay_entity_type_id = 4 and
        osd.to_type               = 1 and
        oe.company_id             = #{cid} and
        #{to_emps_str}
        #{sid_str}
        osd.from_type             = 0
       UNION
        select oe.id as id, oe.name as name, overlay_entity_type_id, overlay_entity_group_id, osd.to_id as kid, osd.value as connections
        from overlay_snapshot_data as osd
        join overlay_entities as oe on osd.to_id = oe.id
        where
        oe.overlay_entity_type_id = 4 and
        osd.from_type             = 1 and
        oe.company_id             = #{cid} and
        #{from_emps_str}
        #{sid_str}
        osd.to_type               = 0
      ) as inner_select
      group by inner_select.id, name, overlay_entity_type_id, overlay_entity_group_id
      order by num desc"
    res = ActiveRecord::Base.connection.select_all(sqlstr)
    return res
  end
end
