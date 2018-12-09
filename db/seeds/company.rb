
company_name = ENV['COMPANY_NAME']
if company_name.nil?
  raise "company_name is empty"
end

company_domain = ENV['COMPANY_DOMAIN']
if company_domain.nil?
  raise "company_domain is empty"
end

Company.find_or_create_by(
  id: 1,
  name: company_name,
  product_type: 'full',
  session_timeout: 3,
  password_update_interval: 1,
  max_login_attempts: 0,
  required_chars_in_password: nil
)

Domain.create!(company_id: 1, domain: company_domain)

Snapshot.create!(name: 'init', timestamp: 1.year.ago, company_id: 1)
