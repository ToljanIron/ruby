include CdsUtilHelper
class EmployeeAliasEmail < ActiveRecord::Base
  validates :email_alias,   presence: true
  validates :employee_id,   presence: true

  def self.build_from_email(email)
    return nil unless CdsUtilHelper.validate_email email
    eae = EmployeeAliasEmail.find_or_create_by(email_alias: email)
    return eae
  end
end
