include CdsUtilHelper

class Group < ActiveRecord::Base
  has_many :employees
  belongs_to :company
  belongs_to :color
  belongs_to :snapshot

  validates :name, presence: true, length: { maximum: 150 }
  validates :company_id, presence: true

  scope :by_company, ->(cid, sid=nil) {
    sid ||= Snapshot.last_snapshot_of_company(cid)
    Group.where(company_id: cid, active: true, snapshot_id: sid)
  }

  scope :by_snapshot, ->(sid) {
    raise 'snapshot_id cant be nil' if sid.nil?
    Group.where(snapshot_id: sid, active: true)
  }

  before_save do
    if snapshot_id.nil?
      sid = Snapshot.last_snapshot_of_company(company_id)
      self.snapshot_id = sid.nil? ? -1 : sid
    end
  end

  def sibling_groups
    Group.where(parent_group_id: parent_group_id, snapshot_id: snapshot_id).where.not(id: id)
  end

  def extract_employees
    cache_key = "Group.extract_employees-#{id}"
    res = cache_read(cache_key)
    if res.nil?
      res = Employee.by_snapshot(snapshot_id).where(group_id: extract_descendants_ids_and_self, active: true).pluck(:id)
      cache_write(cache_key, res)
    end
    res
  end

  def self.num_of_emps(gid)
    cache_key = "Group.num_of_emps-#{gid}"
    res = cache_read(cache_key)
    if res.nil?
      res = Group.find(gid).extract_employees.count
      cache_write(cache_key, res)
    end
    res
  end

  def extract_employees_records
    cache_key = "Group.extract_employees_records-#{id}"
    res = cache_read(cache_key)
    if res.nil?
      res = Employee.by_snapshot(snapshot_id).where(group_id: extract_descendants_ids_and_self, active: true)
      cache_write(cache_key, res)
    end
    res
  end

  def is_emp_in_subgroup(emp_id)
    sid = Snapshot.last_snapshot_of_company(company_id)
    subgroups = extract_descendants_ids

    # sql = "SELECT id FROM employees
    #        WHERE id=#{emp_id} AND
    #        snapshot_id=#{sid} AND
    #        WHERE group_id IN {subgroups.join(',')}
    #        LIMIT 1"

    # Same as above raw sql - just implemented in ruby
    res = Employee.where(id: emp_id, snapshot_id: sid, group_id: subgroups).limit(1)

    return res.count == 1
  end

  #Returns all managers in group and sub-groups
  def get_managers
    res = extract_employees
    hash = {}
    hash[:id] = id
    hash[:manager_id] = EmployeeManagementRelation.by_snapshot(snapshot_id).where(employee_id: res).pluck(:manager_id).uniq
    return hash
  end

  def pack_to_json
    hash = {}
    hash[:id] = id
    hash[:name] = !CompanyConfigurationTable::is_investigation_mode? ? name : "#{english_name}-#{id}"
    hash[:level] = -1  ##group_level(self)
    hash[:child_groups] = extract_descendants_ids
    hash[:employees_ids] = Employee.where(group_id: hash[:child_groups] + [id]).pluck(:id)
    hash[:parent] = parent_group_id
    hash[:snapshot_id] = snapshot_id
    return hash
  end

  def extract_descendants_with_parent_with_parent(groups, root_id, sid)
    res_arr = []
    sid ||= Snapshot.last_snapshot_of_company(company_id)
    res = groups.by_snapshot(sid).where(id: root_id)
    res_arr << res
    sub_groups = groups.by_snapshot(sid).where(parent_group_id: root_id)
    sub_groups.each do |sg|
      groups_active_record_relation = extract_descendants_with_parent_with_parent(groups, sg.id, sid)
      groups_active_record_relation.each {|g| res_arr << g}
    end
    return res_arr
  end

  def extract_descendants_ids_and_self
    groups = extract_descendants_ids
    groups.push(id)
    groups
  end

  def extract_descendants_ids
    res = []
    groups = Group.by_snapshot(snapshot_id)
    groups_active_record_relation_arr = extract_descendants_with_parent_with_parent(groups, id, snapshot_id)
    groups_active_record_relation_arr.each do |gr_relation|
      gr_relation.each {|gr| res.push gr.id}
    end
    res.delete(id)
    res
  end

  def extract_descendants_as_active_record_relation
    groups = Group.by_snapshot(snapshot_id).where(id: extract_descendants_ids)
    return groups
  end

  def root_group?
    return parent_group_id.nil?
  end

  def self.get_root_group(cid, sid=nil)
    raise "Company ID cant be nil" if cid.nil?
    sid = Snapshot.last_snapshot_of_company(cid) if (sid.nil? || sid == -1)
    return Group.by_snapshot(sid)
             .where(company_id: cid)
             .where('parent_group_id is null')
             .first.id
  end

  def self.get_parent_group(cid, sid=nil)
    raise "Company ID cant be nil" if cid.nil?
    sid = Snapshot.last_snapshot_of_company(cid) if (sid.nil? || sid == -1)
    Group.by_snapshot(sid).where(company_id: cid).where("parent_group_id is null").first
  end

  def get_all_parent_groups(parents)
    unless self.parent_group_id.nil?
      parents.push(self.parent_group_id)
      Group.by_snapshot(snapshot_id).find(self.parent_group_id).get_all_parent_groups(parents)
    end
    parents
  end

  def get_all_parent_groups_ids(parents)
    parents = get_all_parent_groups(parents)
    parents.push(nil) unless parents.empty?
    parents
  end

  def self.get_all_subgroups(gid)
    subgroups = Group.where(parent_group_id: gid).pluck(:id)
    return [gid] if subgroups.nil?
    ret = [gid]
    subgroups.each do |sgid|
      ret += Group.get_all_subgroups(sgid)
    end
    return ret
  end

  def self.create_snapshot(cid, prev_sid, sid)
   return if Group.where(snapshot_id: sid).count > 0
   prev_sid = -1 if Group.where(snapshot_id: prev_sid).count == 0

   ActiveRecord::Base.connection.execute(
      "INSERT INTO groups
         (name, company_id, parent_group_id, color_id, created_at, updated_at, external_id, english_name, snapshot_id)
         SELECT name, company_id, parent_group_id, color_id, created_at, updated_at, external_id, english_name, #{sid}
         FROM groups
         WHERE
           snapshot_id = #{prev_sid} AND
           company_id = #{cid} AND
           #{sql_check_boolean('active', true)}"
   )

   ## Fix parent group IDs
   Group.by_snapshot(sid).each do |currg|
     parent_in_prev_sid = currg.parent_group_id
     next if parent_in_prev_sid.nil?
     external_id = Group.find(parent_in_prev_sid).external_id
     parent_in_sid = Group.by_snapshot(sid).where(external_id: external_id).last
     currg.update(parent_group_id: parent_in_sid.id)
   end
  end

  ## Since the group id changes with the snapshot id, sometimes we're going to
  ## have an older group id which doesn't belong with the given snapshot. This
  ## method will return the updated group id, based on it's external id.
  def self.find_group_in_snapshot(gid, sid)
    orig_group = Group.find(gid)
    return gid.to_i if orig_group.snapshot_id == sid
    external_id = orig_group.external_id
    new_group = Group.where(external_id: external_id, snapshot_id: sid).last
    return new_group.id if !new_group.nil?
    return gid
  end

  ## Same as above, only for multiple groups at once
  def self.find_groups_in_snapshot(gids, sid)
    return [] if gids.length == 0
    sqlstr = "
      SELECT yg.id, yg.name, yg.external_id, yg.snapshot_id
      FROM groups AS xg
      JOIN groups AS yg on xg.external_id = yg.external_id
      WHERE
        xg.id IN (#{gids.join(',')}) AND
        yg.snapshot_id = #{sid}"
   return ActiveRecord::Base.connection.select_all(sqlstr).to_a
  end

  def self.find_group_ids_in_snapshot(gids, sid)
    res = []
    groups = find_groups_in_snapshot(gids, sid)
    groups.each {|e| res << e['id']}
    return res
  end

  def self.external_id_to_id_in_snapshot(extid, sid)
    key = "group_external_id_to_id_in_snapshot-sid-#{sid}"
    extid2id = Rails.cache.fetch(key)
    return extid2id[extid] if extid2id
    extid2id = {}
    res = Group
            .select(:id, :external_id)
            .where(snapshot_id: sid)
    res.each do |r|
      extid2id[r.external_id] = r.id
    end
    Rails.cache.write(key, extid2id, expires_in: 1.minutes)
    return extid2id[extid]
  end
end
