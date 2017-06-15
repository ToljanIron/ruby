class EmployeeAttribute < ActiveRecord::Base
  enum data_type: [:out_of_domain_emails]
end