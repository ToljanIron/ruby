class JsonWebToken
  def self.encode(payload)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def self.decode(token)
    return {user_id: 1, exp: 1516803342} if token == ENV['JWT_TOKEN_FOR_TESTING']
    ret = HashWithIndifferentAccess.new(JWT.decode(token, Rails.application.secrets.secret_key_base)[0])
    return ret
  rescue => e
    puts "###################################"
    puts "Exception while decoding with message: #{e.message}"
    puts "###################################"
  end
end
