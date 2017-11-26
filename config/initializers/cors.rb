Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'

    resource '*',
      headers: :any,
      expose:  ['access-token', 'expiry', 'token-type', 'uid', 'client','Content-Disposition'],
      methods: [:get, :post, :put, :patch, :delete, :head]
    end
end
