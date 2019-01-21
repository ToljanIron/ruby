if Rails.env.production? || Rails.env.onpremise?
  Dotenv.load ## DO NOT COMMIT
  Workships::Application.config.secret_key_base = ENV["SECRET_KEY"]
else
  Workships::Application.config.secret_key_base = '6216a3790c60fbe28d9fefb2bd987c70f28de65f25dfd3b2718aeba4a6391cca798d980c65b7eb2a46d932d95cc7aa4e76e8ef8abece4cc629ce45e8c34a7363'
end
