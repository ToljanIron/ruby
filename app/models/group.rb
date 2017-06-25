include UtilHelper

class Group < ActiveRecord::Base
  has_many :employees
  belongs_to :company
  belongs_to :color
  belongs_to :snapshot

  validates :name, presence: true, length: { maximum: 150 }
  validates :company_id, presence: true

  scope :by_snapshot, ->(sid) {
    raise 'snapshot_id cant be nil' if sid.nil?
    Group.where(snapshot_id: sid)
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
    hash[:name] = !CompanyConfigurationTable::is_investigation_mode? ? name : "#{id}-#{name}"
    hash[:level] = group_level(self)
    hash[:child_groups] = extract_descendants_ids
    hash[:employees_ids] = Employee.where(group_id: hash[:child_groups] + [id]).pluck(:id)
    hash[:parent] = parent_group_id
    hash[:snapshot_id] = snapshot_id
    return hash
  end

  def extract_descendants_with_parent_with_parent(groups, root_id, sid)
    sid ||= Snapshot.last_snapshot_of_company(company_id)
    res = groups.by_snapshot(sid).where(id: root_id)
    sub_groups = groups.by_snapshot(sid).where(parent_group_id: root_id)
    sub_groups.each do |sg|
      groups_active_record_relation = extract_descendants_with_parent_with_parent(groups, sg.id, sid)
      groups_active_record_relation.each do |g|
        res << g
      end
    end
    res
  end

  def extract_descendants_ids_and_self
    groups = extract_descendants_ids
    groups.push(id)
    groups
  end

  def extract_descendants_ids
    res = []
    groups = Group.by_snapshot(snapshot_id)
    groups_active_record_relation = extract_descendants_with_parent_with_parent(groups, id, snapshot_id)
    groups_active_record_relation.each do |g|
      res.push g.id
    end
    res.delete(id)
    res
  end

  def root_group?
    return parent_group_id.nil?
  end

  def self.get_root_group(cid)
    return Group.by_snapshot(snapshot_id).where(company_id: cid).where('parent_group_id is null').first.id
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

  def self.create_snapshot(prev_sid, sid)
   return if Group.where(snapshot_id: sid).count > 0
   prev_sid = -1 if Group.where(snapshot_id: prev_sid).count == 0

   ActiveRecord::Base.connection.execute(
      "INSERT INTO groups
         (name, company_id, parent_group_id, color_id, created_at, updated_at, external_id, english_name, snapshot_id)
         SELECT name, company_id, parent_group_id, color_id, created_at, updated_at, external_id, english_name, #{sid}
         FROM groups
         WHERE snapshot_id = #{prev_sid} and active is true"
    )
  end

  private

  def set_default_snapshot
    cid = Company.find(company_id).id
    sid = Snapshot.last_snapshot_of_company(cid)
    update(snapshot_id: sid)
    return sid
  end
end
