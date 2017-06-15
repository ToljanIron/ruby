module CdsSelectionHelper
  NO_PIN = -1
  NO_GROUP = -1

  ID      = 0
  MEASURE = 1

  def self.get_inner_select(pinid, gid)
    return CdsGroupsHelper.get_inner_select_by_group(gid)    if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin(pinid)    if pinid != NO_PIN && gid == NO_GROUP
    fail 'Ambiguous sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    return nil
  end

  def self.get_inner_select_as_arr(cid, pinid, gid)
    return CdsGroupsHelper.get_inner_select_by_group_as_arr(gid) if pinid == NO_PIN && gid != NO_GROUP
    return CdsPinsHelper.get_inner_select_by_pin_as_arr(pinid) if pinid != NO_PIN && gid == NO_GROUP
    fail 'Ambigious sub-group request with both pin-id and group-id' if pinid != NO_PIN && gid != NO_GROUP
    ret = Employee.where(company_id: cid).where('email != ?', 'other@mail.com').select(:id).map { |entry| entry[:id] }
    return ret
  end

  def self.format_from_activerecord_result(f_in_n)
    ret = []
    f_in_n.rows.each do |row|
      ret << { id: row[ID].to_i, measure: row[MEASURE] }
    end
    return ret
  end
end
