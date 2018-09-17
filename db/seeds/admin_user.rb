user = User.find_by_email('admin@step-ahead.com')
pass = ENV['ADMIN_USER_PASSWORD']
raise 'Cant create user, missing password' if pass.nil?

if user.nil?
  User.create!(
    first_name: 'admin',
    company_id: 1,
    email: 'admin@step-ahead.com',
    role: 0,
    password: ENV['ADMIN_USER_PASSWORD'])
end
