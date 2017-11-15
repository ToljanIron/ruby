class User < ActiveRecord::Base
  ROLE_ADMIN   = 'admin'
  ROLE_HR      = 'hr'
  ROLE_EMP     = 'emp'
  ROLE_MANAGER     = 'manager'

  attr_accessor :undigest_token

  before_save { self.email = email.downcase }
  before_create :create_remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence:   true,
  format:     { with: VALID_EMAIL_REGEX },
  uniqueness: { case_sensitive: false }
  has_secure_password
  validates :first_name, length: { maximum: 50 }
  validates :last_name, length: { maximum: 40 }

  enum role: [:admin, :hr, :emp, :manager]

  validates :group_id, presence: true, if: :is_manager?

  validates :document_encryption_password, length: { minimum: 7 }, :allow_blank => true

  def is_manager?
    return role == ROLE_MANAGER
  end

  scope :not_expired, -> { where('tmp_password_expiry > ?', DateTime.now) }

  def self.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
    BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.undigest_token = User.new_token
    update_attribute(:remember_token, User.digest(undigest_token))
  end

  def authenticated?(token)
    begin
      BCrypt::Password.new(remember_token).is_password?(token)
    rescue => e
      error = e.message
      puts "Got exception : #{error}. User was not authenticated."
      false
    end
  end

  def forget
    update_attribute(:remember_token, nil)
  end

  def generate_password_reset_token
    begin
      update_attribute(:password_reset_token, SecureRandom.urlsafe_base64(48))
      update_attribute(:password_reset_token_expiry, DateTime.now + 1.week)
    rescue => e
      error = e.message
      puts "Got exception: #{error}. Rolling back."
      puts e.backtrace
    end
  end

  def send_reset_password_mail(base_url)
    mail = nil
    begin
      mail = UserMailer.reset_password_email(email, password_reset_token, base_url).deliver_now! unless Rails.env.test?
      mail = {} if Rails.env.test?
    rescue => e
      error = e.message
      puts "Got exception: #{error}. Rolling back."
      puts e.backtrace
    end
    return mail
  end

  def authenticate_by_tmp_password?(temporary_password)
    BCrypt::Password.new(tmp_password).is_password?(temporary_password) if tmp_password
  end

  def self.verify_password_token(token)
    @current_user = User.find_by(password_reset_token: token)
    if @current_user && @current_user.password_reset_token_expiry > DateTime.now
      return true
    else
      return false
    end
  end

  private

  def create_remember_token
    self.remember_token = User.digest(User.new_remember_token)
  end

  public

  def update_user_info(first_name, last_name, doc_encryption_pass)
    update_attribute(:first_name, first_name)
    update_attribute(:last_name, last_name)
    update_attribute(:document_encryption_password, doc_encryption_pass)
    return
  end

  def update_password(old_password, new_password)
    if(BCrypt::Password.new(password_digest).is_password?(old_password))
      update!(email: email, password: new_password)
      return true
    end
    return false
  end
end
