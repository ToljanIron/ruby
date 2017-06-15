module WordCloudHelper
  def self.get_word_cloud_for_group(cid, gid, sid)
    res = {}
    keywords_type_id = OverlayEntityType.where(overlay_entity_type: 1, name: 'keywords').first.try(:id)
    return res unless keywords_type_id
    emp_ids_in_group = if gid
                           Group.find(gid).extract_employees
                         else
                           Employee.where(company_id: cid).pluck(:id)
                         end
    words = OverlayEntity.get_keywords(cid, emp_ids_in_group, sid)
    words[0..49].map { |word| res[word['name']] = word['num'].to_i }
    return res
  end
end
