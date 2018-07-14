FactoryGirl.define do
  factory :employee do
    first_name 'fst_name'
    last_name 'lst_name'
    sequence(:email) { |n| "employee#{n}@domain.com" }
    company_id 1
    group_id 1
    sequence(:external_id) { |n| "#{n}" }
    active true
  end

  factory :group_employee, class: Employee do
    first_name 'fst_name'
    last_name 'lst_name'
    sequence(:email) { |n| "employee#{n}@domain.com" }
    company_id 1
    group_id 1
    sequence(:external_id) { |n| "#{n}" }
  end
end

########################################################
## Will create multiple employees
## - times - how many employees should be created
## - p - Is a parameters hash the can contain:
##     - gid - A specific group ID, default is 1
##     - sid - A specific snapshot ID, default is 1
##     - oid - A specific office ID, default is 1
##     - from_index - An index for the IDs to start from
#########################################################
def create_emps(name, domain, times, p = nil)
  p = p || {}
  gid = p[:gid] || 1
  sid = p[:sid] || 1
  oid = p[:oid] || 1
  active = p[:active] || true
  from_index = p[:from_index] || 1

  (from_index..from_index + times - 1).each do |n|
    email = "#{name}#{n}@#{domain}"
    FactoryGirl.create(:employee, email: email, group_id: gid, snapshot_id: sid, office_id: oid, active: active)
  end
end
