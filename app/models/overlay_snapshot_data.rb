class OverlaySnapshotData < ActiveRecord::Base
  enum from_type: [:from_overlay_entity, :from_employee]
  enum to_type: [:to_overlay_entity, :to_employee]

  def self.pick_by_group(cid, oegid, ids, gid, type_ids, s_id)
    # return OverlaySnapshotData.all unless oegid
    return if (oegid.nil? || oegid.empty?) && (ids.nil? || ids.empty?)
    ids_in_group = OverlayEntity.where(overlay_entity_group_id: oegid, overlay_entity_type_id: type_ids).pluck(:id) + OverlayEntity.where(id: ids).pluck(:id)
    return [] if ids_in_group.empty?
    ids_in_group = '(' + ids_in_group.join(',') + ')'
    emp_ids_in_group = if gid
                         "(#{Group.find(gid).extract_employees.join(',')})"
                       else
                         "(#{Employee.where(company_id: cid).pluck(:id).join(',')})"
                       end
    res = ActiveRecord::Base.connection.select_all(
      'select osd.* from overlay_snapshot_data as osd ' \
      'where ((osd.from_type = 0 ' \
      "and osd.from_id in #{ids_in_group} and to_id in #{emp_ids_in_group})" \
      'or (osd.to_type = 0 ' \
      "and osd.to_id in #{ids_in_group} and from_id in #{emp_ids_in_group}) and snapshot_id = #{s_id})"
    ).to_json

    res = JSON.parse(res)
    res.each do |obj|
      obj['from_type'] = obj['from_type'].to_s == '0' ? 'overlay_entity' : 'single'
      obj['to_type'] = obj['to_type'].to_s == '0' ? 'overlay_entity' : 'single'
      obj['from_id'] = obj['from_id'].to_i
      obj['to_id'] = obj['to_id'].to_i
      obj['snapshot_id'] = obj['snapshot_id'].to_i
      obj['weight'] = obj['value'].to_i
    end
    return res
  end

  def self.number_connected_to_group(sid, gid, type_id)
    emp_ids_in_group = "(#{Group.find(gid).extract_employees.join(',')})"
    oes_of_type = "(#{OverlayEntity.where(overlay_entity_type_id: type_id).pluck(:id).join(',')})"
    res1 = ActiveRecord::Base.connection.select_all(
      'select * from overlay_snapshot_data as osd ' \
      'where (osd.from_type = 0 ' \
      "and from_id in #{oes_of_type} " \
      "and to_id in #{emp_ids_in_group})" \
      "and snapshot_id = #{sid}"
    ).to_json

    res2 = ActiveRecord::Base.connection.select_all(
      'select * from overlay_snapshot_data as osd ' \
      'where (osd.to_type = 0 ' \
      "and to_id in #{oes_of_type} " \
      "and from_id in #{emp_ids_in_group})" \
      "and snapshot_id = #{sid}"
    ).to_json
    res1 = JSON.parse(res1)
    res2 = JSON.parse(res2)
    return res1.size + res2.size
  end

  def self.pick_employees_by_id_and_snapshot(id, sid)
    if id.nil?
      return OverlaySnapshotData.where(snapshot_id: sid).map do |osd|
        return osd[:from_id] if osd.from_employee?
        return osd[:to_id] if osd.to_employee?
      end
    end
    res = ActiveRecord::Base.connection.select_all(
      'select osd.to_id from overlay_snapshot_data as osd ' \
      "where osd.snapshot_id = #{sid} " \
      'and osd.from_type = 0 and osd.to_type = 1 ' \
      "and osd.from_id = #{id} " \
      'union select osd.from_id from overlay_snapshot_data as osd ' \
      "where osd.snapshot_id = #{sid} " \
      'and osd.to_type = 0 and osd.from_type = 1 ' \
      "and osd.to_id = #{id}"
    ).to_json
    res = JSON.parse(res)
    return res.map { |obj| (obj['to_id'] || obj['from_id']).to_i }
  end

  def self.pick_employees_by_group_and_snapshot(gid, sid)
    if gid.nil?
      return OverlaySnapshotData.where(snapshot_id: sid).map do |osd|
        return osd[:from_id] if osd.from_employee?
        return osd[:to_id] if osd.to_employee?
      end
    end
    ids_in_group = '(' + OverlayEntity.where(overlay_entity_group_id: gid).pluck(:id).join(',') + ')'
    res = ActiveRecord::Base.connection.select_all(
      'select osd.to_id from overlay_snapshot_data as osd ' \
      "where osd.snapshot_id = #{sid} " \
      'and osd.from_type = 0 and osd.to_type = 1 ' \
      "and osd.from_id in #{ids_in_group} " \
      'union select osd.from_id from overlay_snapshot_data as osd ' \
      "where osd.snapshot_id = #{sid} " \
      'and osd.to_type = 0 and osd.from_type = 1 ' \
      "and osd.to_id in #{ids_in_group}"
    ).to_json
    res = JSON.parse(res)
    return res.map { |obj| (obj['to_id'] || obj['from_id']).to_i }
  end

  # def as_json(options = {})
  #   super(options).merge(
  #     weight: value || 0,
  #     from_type: from_type == 'from_overlay_entity' ? 'overlay_entity' : 'single',
  #     to_type: to_type == 'to_overlay_entity' ? 'overlay_entity' : 'single'
  #   )
  # end
end
