include CdsUtilHelper
class Employee < ActiveRecord::Base

  DIRECT_MANAGER = 0
  PRO_MANAGER = 1

  attr_accessor :group_name
  has_many    :employee_alias_email
  belongs_to  :group
  belongs_to  :office
  belongs_to  :role
  belongs_to  :age_group
  belongs_to  :seniority
  belongs_to  :rank
  belongs_to  :color
  belongs_to  :job_title
  belongs_to  :marital_status
  has_and_belongs_to_many :pins

  has_many    :email_subject_snapshot_data
  has_many    :netowrk_snapshot_data

  has_many    :questionnaire_participants

  has_and_belongs_to_many :managers,     class_name: 'EmployeeManagementRelation', join_table: 'employee_management_relations', foreign_key: :employee_id, association_foreign_key: :manager_id
  has_and_belongs_to_many :team_members, class_name: 'EmployeeManagementRelation', join_table: 'employee_management_relations', foreign_key: :manager_id,  association_foreign_key: :employee_id

  before_save      do
    self.email       = email.strip.downcase
    self.first_name  = safe_titleize(first_name.strip)
    self.last_name   = safe_titleize(last_name.strip)
    if snapshot_id.nil?
      sid = Snapshot.last_snapshot_of_company(company_id)
      self.snapshot_id = sid.nil? ? -1 : sid
    end
  end

  validates :email, presence:   true, format:     { with: CdsUtilHelper::VALID_EMAIL_REGEX }
  validates :company_id, presence: true
  validates :external_id, presence: true, length: { maximum: 50 }
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }

  validates_numericality_of :position_scope, only_integer: true, allow_nil: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100

  scope :aliases, ->(id) { EmployeeAliasEmail.where(employee_id: id) }
  scope :by_company, ->(cid, sid=nil) {
    sid ||= Snapshot.last_snapshot_of_company(cid)
    Employee.where(company_id: cid, active: true, snapshot_id: sid).where.not(email: 'other@mail.com')
  }
  scope :size, ->() { Employee.count }
  scope :by_snapshot, ->(sid) {
    raise 'snapshot_id cant be nil' if sid.nil?
    Employee.where(snapshot_id: sid, active: true).where.not(email: 'other@mail.com')
  }

  enum gender: [:male, :female]

  def self.job_title_by_company(cid)
    ret = []
    el = Employee.by_company(cid).where('job_title_id IS NOT NULL').includes(:job_title)

    el.each do |jt_name|
      ret << jt_name.job_title.name
    end
    ret
  end

  def self.direct_managers_by_company(cid, sid=nil)
    sid ||= Snapshot.last_snapshot_of_company(cid)
    first_names = Employee.by_snapshot(sid).joins("JOIN employee_management_relations  ON employee_management_relations.manager_id = employees.id AND employee_management_relations.relation_type = #{DIRECT_MANAGER}").pluck(:first_name)
    first_names = first_names.map { |x| x + ' ' }
    last_names  = Employee.by_snapshot(sid).joins("JOIN employee_management_relations  ON employee_management_relations.manager_id = employees.id AND employee_management_relations.relation_type = #{DIRECT_MANAGER}").pluck(:last_name)
    names = first_names.zip(last_names).map { |a| a.inject(:+) }
    return names
  end

  def self.pro_managers_by_company(cid, sid=nil)
    sid ||= Snapshot.last_snapshot_of_company(cid)
    first_names = Employee.by_snapshot(sid).joins("JOIN employee_management_relations  ON employee_management_relations.manager_id = employees.id AND employee_management_relations.relation_type = #{PRO_MANAGER}").pluck(:first_name)
    first_names = first_names.map { |x| x + ' ' }
    last_names  = Employee.by_snapshot(sid).joins("JOIN employee_management_relations  ON employee_management_relations.manager_id = employees.id AND employee_management_relations.relation_type = #{PRO_MANAGER}").pluck(:last_name)
    names = first_names.zip(last_names).map { |a| a.inject(:+) }
    return names
  end

  def extract_descendants_with_parent(managment, root_id)
    res = []
    sub_subordinates = managment.where(manager_id: root_id)
    sub_subordinates.each do |so|
      res.push(so.employee_id)
      managment_active_record_relation = extract_descendants_with_parent(managment, so.employee_id)
      res |= managment_active_record_relation
    end
    res
  end

  def check_img_url
    return 'dummy_s3_img_url' if ENV['RAILS_ENV'] == 'test'

    s3 = AWS::S3.new(access_key_id: ENV['s3_access_key'], secret_access_key: ENV['s3_secret_access_key'])
    return randomize_img_url_from_db(s3) if randomize_image?
    object = s3.buckets['workships'].objects.with_prefix(email).collect(&:key)
    if object.length > 0
      object = s3.buckets['workships'].objects["#{email}.jpg"]
      img_url = object.url_for(:get, secure: true, expires:  24.hour).to_s
    else
      object = s3.buckets['workships'].objects['missing.jpg']
      img_url = object.url_for(:get, secure: true, expires:  24.hour).to_s
    end
    return img_url
  end

  def get_direct_manager(eid)
    get_manager(eid, 'direct')
  end

  def get_professional_manager(eid)
    get_manager(eid, 'professional')
  end

  def get_manager(eid, type)
    manager_relation = EmployeeManagementRelation.find_by(employee_id: eid, relation_type: type)
    res = {}
    if manager_relation
      m = Employee.find(manager_relation.manager_id)
      res = {
        id: manager_relation.manager_id,
        first_name: m.first_name,
        last_name: m.last_name
      }
    end
    return res
  end

  def pack_to_json(managers_hash = nil)
    attrs = %i(id email first_name last_name company_id group_id formal_level snapshot_id)
    h = {}
    attrs.each do |a|
      h[a] = self[a]
    end
    h[:img_url] =  img_url ? img_url : '/assets/missing_user.jpg'
    h[:rank] = rank.name if rank
    h[:role_type] = role.name if role
    h[:gender] = gender
    h[:subordinates] = EmployeeManagementRelation.where(manager_id: id, relation_type: 2).pluck(:employee_id)
    h[:age] = CdsUtilHelper.calc_age_from_now(date_of_birth)
    h[:age_group] = age_group.name if age_group
    h[:group_name] = group.name if group
    h[:job_title] = job_title.name if job_title
    h[:marital_status] = marital_status.name if marital_status
    h[:office] = office.name if office
    h[:seniority] = seniority.name if seniority

    direct_manager_name = nil
    direct_manager_id   = nil

    if !managers_hash.nil?
      direct_manager_name = managers_hash[id.to_s].nil? ? nil : managers_hash[id.to_s][:manager_name]
      direct_manager_id   = managers_hash[id.to_s].nil? ? nil : managers_hash[id.to_s][:manager_id].to_i
    else
      dm = get_direct_manager(id)
      direct_manager_name = "#{dm[:first_name]} #{dm[:last_name]}" if dm
      direct_manager_id   = dm['id']
    end

    h[:direct_manager]      = direct_manager_name
    h[:manager_id]          = direct_manager_id
    h[:professioal_manager] = nil

    return h
  end

  def randomize_image?
    return Company.find(company_id).randomize_image
  end

  def randomize_img_url_from_db(s3)
    image_name = StackOfImage.random_image(self) || 'missing.jpg'
    object = s3.buckets['workships'].objects[image_name]
    img_url = object.url_for(:get, secure: true, expires: 24.hour).to_s
    return img_url
  end

  def self.build_from_hash(attrs)
    errors = []
    processed_attrs = attrs.clone

    sid = Snapshot.last_snapshot_of_company(processed_attrs[:company_id])
    processed_attrs[:snapshot_id] = sid

    alias_emails  = processed_attrs.delete(:alias_emails)   if processed_attrs[:alias_emails]
    qualifications = processed_attrs.delete(:qualifications) if processed_attrs[:qualifications]

    group_name = processed_attrs.delete(:group_name) if valid_attr_field processed_attrs[:group_name]
    processed_attrs.delete(:delete)

    marital_status = processed_attrs.delete(:marital_status) if  processed_attrs[:marital_status]
    rank = processed_attrs.delete(:rank) if  processed_attrs[:rank]
    role = processed_attrs.delete(:role) if  processed_attrs[:role]
    job_title = processed_attrs.delete(:job_title) if  processed_attrs[:job_title]
    office_address = processed_attrs.delete(:office_address) || ''

    processed_attrs[:work_start_date] = CdsUtilHelper.convert_str_to_date(processed_attrs[:work_start_date]) if valid_attr_field processed_attrs[:work_start_date]
    processed_attrs[:date_of_birth] = CdsUtilHelper.convert_str_to_date(processed_attrs[:date_of_birth]) if valid_attr_field processed_attrs[:alias_emails]

    check_enums(processed_attrs, errors)
    begin
      e = Employee.find_by(external_id: processed_attrs[:external_id], company_id: processed_attrs[:company_id], snapshot_id: sid)
      e.update(processed_attrs) if e
      e = Employee.create!(processed_attrs) unless e
    rescue => e
      logger.error e.message
      logger.error e.backtrace.join("\n")
      raise 'Employee.build_from_hash: Error - faild to build Employee'
    end
    return {
      employee:       e,
      alias_emails:   alias_emails,
      qualifications: qualifications,
      group_name:     group_name,
      marital_status: marital_status,
      rank: rank,
      role: role,
      job_title: job_title,
      office_address: office_address,
      errors:         errors
    }
  end

  def self.create_snapshot(cid, prev_sid, sid)
    return if Employee.where(snapshot_id: sid).count > 0
    prev_sid = -1 if Employee.where(snapshot_id: prev_sid).count == 0
    raise 'Groups have to be bumped into new snapshot before employees' if (Group.by_snapshot(sid).count == 0)
    create_snapshot_employees(cid, prev_sid, sid)
    #create_snapshot_managers(cid, prev_sid, sid)
  end

  private

  def self.create_snapshot_employees(cid, prev_sid, sid)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO employees
         (company_id, email, external_id, first_name, last_name, date_of_birth, employment, gender, group_id,
         home_address, job_title_id, marital_status_id, middle_name, position_scope, qualifications, rank_id,
         role_id, office_id, work_start_date, img_url, img_url_last_updated, color_id, created_at, updated_at,
         age_group_id, seniority_id, formal_level, active, phone_number, id_number, snapshot_id)
         SELECT emps.company_id, email, emps.external_id, first_name, last_name, date_of_birth, employment, gender,
                new_group.id, home_address, job_title_id, marital_status_id, middle_name, position_scope, qualifications, rank_id,
                role_id, office_id, work_start_date, img_url, img_url_last_updated, emps.color_id, emps.created_at, emps.updated_at,
                age_group_id, seniority_id, formal_level, emps.active, phone_number, id_number, #{sid}
         FROM employees as emps
         JOIN groups AS orig_group ON orig_group.id = emps.group_id
         JOIN groups AS new_group ON new_group.external_id = orig_group.external_id and new_group.snapshot_id = #{sid}
         WHERE
         emps.snapshot_id = #{prev_sid} AND
         emps.company_id = #{cid} AND
         #{sql_check_boolean('emps.active', true)} AND
         emps.email <> 'other@email.com'"
    )
  end

  def self.create_snapshot_managers(cid, prev_sid, sid)
    oldemps = Employee.by_snapshot(prev_sid).where(company_id: cid).select(:id,:external_id)
    oldempsids = oldemps.pluck(:id)
    newemps = Employee.by_snapshot(sid).where(company_id: cid).select(:id,:external_id)
    emps_hash = {}
    oldemps.each do |oemp|
      nemp = newemps.select{ |e| e.external_id == oemp.external_id }.last
      emps_hash[oemp.id] = nemp.id
    end
    managers = EmployeeManagementRelation.where(manager_id: oldempsids, employee_id: oldempsids)
    managers.each do |m|
      next if (emps_hash[m.manager_id].nil? || emps_hash[m.employee_id].nil?)
      EmployeeManagementRelation.create!(
        manager_id: emps_hash[m.manager_id],
        employee_id: emps_hash[m.employee_id],
        relation_type: m.relation_type
      )
    end
  end

  def self.check_enums(processed_attrs, errors)
    if !Employee.genders.keys.include? processed_attrs[:gender]
      errors.push 'gender'
      processed_attrs[:gender] = nil
    end
    return
  end

  def self.valid_attr_field(attr_field)
    return attr_field && !attr_field.empty?
  end

  def self.id_in_snapshot(eid, sid=nil)
    old_sid = Employee.find(eid).try(:snapshot_id)
    raise "No such employee for ID: #{eid}" if old_sid.nil?
    key = "employee-id_in_snapshot-old_sid-#{old_sid}-new_sid-#{sid}"
    ids_map = cache_read(key)
    if (ids_map.nil?)
      if (sid.nil?)
        cid = Snapshot.find(old_sid).try(:company_id)
        sid = Snapshot.last_snapshot_of_company(cid)
      end
      ids_map = create_id_map(old_sid, sid)
      cache_write(key, ids_map)
    end
    return ids_map[eid]
  end

  def self.create_id_map(old_sid, new_sid)
    cid = Snapshot.find(new_sid).company_id
    sqlstr =
      "select pre.id as oldid, post.id as newid
      from employees as pre
      join employees as post on post.external_id = pre.external_id
      where
        pre.snapshot_id  = #{old_sid} and
        post.snapshot_id = #{new_sid} and
        pre.company_id   = #{cid} and
        post.company_id  = #{cid}"
    res = ActiveRecord::Base.connection.execute(sqlstr)
    ret = {}
    res.each do |e|
      ret[e['oldid']] = e['newid']
    end
    return ret
  end
end
