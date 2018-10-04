Company.find_or_create_by(
  id: 1,
  name: 'Acme',
  product_type: 'full',
  session_timeout: 3,
  password_update_interval: 1,
  max_login_attempts: 0,
  required_chars_in_password: nil
)

Domain.create(company_id: 1, domain: 'acme.com')
