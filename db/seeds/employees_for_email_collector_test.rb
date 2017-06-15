c = Company.first
g = Group.create(
  name: c.name,
  company_id: c.id
)
(1..5).each do |i|
  Employee.create(
    company_id: c.id,
    first_name: "ex_#{i}",
    last_name: "ex_#{i}",
    email: "ex_#{i}@spectory.com",
    external_id: "ex_#{i}@spectory.com",
    group_id: g.id
  )
end

Employee.create(
  company_id: c.id,
  first_name: "admin",
  last_name: "admin",
  email: "administrator@spectory.local",
  external_id: "administrator@spectory.local",
  group_id: g.id
)
