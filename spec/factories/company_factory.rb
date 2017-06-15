include SessionsHelper

FactoryGirl.define do
   factory :company do
     id 1
     name 'Acme'
   end
end

def create_companies_data
  create_companies
  create_cemployees
  create_cgroups
  create_csnapshots
end

def log_in_with_dummy_user_for_company(cid)
  @user = User.create!(first_name: 'name', email: "user#{cid}@company.com", password: 'qwe123', password_confirmation: 'qwe123', company_id: cid)
  log_in @user
end

def log_in_with_dummy_user_with_role(role, cid = 1)
  @user = User.create!(first_name: 'name', email: "user1@company.com", password: 'qwe123', password_confirmation: 'qwe123', company_id: cid, role: role.to_i)
  log_in @user
end

private
def create_companies
  Company.create(id: 2, name: "Comp2")
  Company.create(id: 3, name: "Comp3")
  Company.create(id: 4, name: "Comp4")
end

def create_cemployees
  (1..15).each do |i|
    id = i%3 + 2
    FactoryGirl.create(:employee,email: "q#{i}@mail.com", company_id: id)
  end
end

def create_cgroups
  Group.create(name: 'group_1', company_id: 2)
  Group.create(name: 'group_2', company_id: 2)
  Group.create(name: 'group_3', company_id: 3)
  Group.create(name: 'group_4', company_id: 4)
end

def create_csnapshots
  FactoryGirl.create(:snapshot, company_id: 2, status: Snapshot::STATUS_ACTIVE, snapshot_type: nil)
  FactoryGirl.create(:snapshot, company_id: 3, status: Snapshot::STATUS_ACTIVE, snapshot_type: nil)
  FactoryGirl.create(:snapshot, company_id: 3, status: Snapshot::STATUS_ACTIVE, snapshot_type: nil)
  FactoryGirl.create(:snapshot, company_id: 4, status: Snapshot::STATUS_ACTIVE, snapshot_type: nil)
end
