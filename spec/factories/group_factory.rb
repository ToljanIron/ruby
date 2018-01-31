FactoryGirl.define do
  factory :group do
    sequence(:name) { |n| "group_#{n}" }
    sequence(:external_id) { |n| "group_#{n}" }
    company_id 1
    snapshot_id 1
  end
end

def bump_groups_snpashot(prev_sid, sid)
  possbile_groups = Employee.where(snapshot_id: prev_sid).select(:company_id, :group_id).distinct
  possbile_groups.each do |pg|
    g = Group.find_by(company_id: pg.company_id, id: pg.group_id,)
    if g.nil?
      name = "G-#{pg.company_id}-#{pg.group_id}-#{prev_sid}"
      FactoryGirl.create(:group, company_id: pg.company_id, id: pg.group_id, snapshot_id: prev_sid, name: name, external_id: name)
    end
  end

  maxid = Group.maximum(:id)
  (0..maxid).each { next_group_sequence_val }
  Group.create_snapshot(prev_sid, sid)
end

def next_group_sequence_val
  ActiveRecord::Base.connection.execute("SELECT nextval('groups_id_seq')")
end
