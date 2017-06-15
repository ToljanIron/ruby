# frozen_string_literal: true
require './app/helpers/util_helper.rb'

module EmailPropertiesTranslator
  # extend ActiveSupport::Concern
  OTHER = 0

  ONE2ONE  = 1
  ONE2MANY = 2

  INITIATE = 1
  REPLY    = 2
  FORWARD  = 3

  TO  = 1
  CC  = 2
  BCC = 3

  def process_email(raw_data_entry, company_id)
    sender = convert_emails_to_employee_ids(raw_data_entry[:from], company_id)
    return [] unless sender
    recipients = {
      TO  => convert_emails_array_to_employee_ids(raw_data_entry[:to],   company_id),
      CC  => convert_emails_array_to_employee_ids(raw_data_entry[:cc],   company_id),
      BCC => convert_emails_array_to_employee_ids(raw_data_entry[:bcc],  company_id)
    }
    multy_type = find_multiplicity_type(raw_data_entry)
    email_type = find_email_relation(raw_data_entry)
    res = []
    recipients.each do |key, val|
      val.each do |emp_id|
        res << {
          from_employee_id: sender,
          to_employee_id:   emp_id,
          message_id:       raw_data_entry[:message_id],
          multiplicity:     multy_type,
          from_type:        email_type,
          to_type:          key,
          email_date:       raw_data_entry[:email_date],
        }
      end
    end
    return res
  end

  # Return array of [{:sender, :recipent, :interaction_type}, ...]
  def process_email_relations(raw_data_entry, company_id)
    multiplicity = find_multiplicity_type raw_data_entry
    email_relation = find_email_relation raw_data_entry
    sender = convert_emails_to_employee_ids(raw_data_entry[:from], company_id)

    return [] unless sender

    recipents = []
    recipents[TO]  = convert_emails_array_to_employee_ids(raw_data_entry[:to], company_id)
    recipents[CC]  = convert_emails_array_to_employee_ids(raw_data_entry[:cc], company_id)
    recipents[BCC] = convert_emails_array_to_employee_ids(raw_data_entry[:bcc], company_id)
    return convert_relations_to_arr(sender, recipents, multiplicity, email_relation)
  end

  def process_email_subject(raw_data_entry, company_id)
    return [] if raw_data_entry[:from].nil?
    sender = email_to_employee_id(raw_data_entry[:from], company_id)
    subject = raw_data_entry[:subject]
    to_arr = convert_emails_array_to_employee_ids(raw_data_entry[:to], company_id)
    ret = []
    to_arr.each do |to|
      ret << {
        employee_from_id: sender,
        employee_to_id:   to,
        subject:          subject
      }
    end
    return ret
  end

  def self.convert_email_to_employee_id(email, company_id)
    email_to_employee_id(email, company_id)
  end

  private

  # Return ONE2ONE or ONE2MANY
  def find_multiplicity_type(raw_data_entry)
    recipents =  to_array(raw_data_entry[:to]).length
    recipents += to_array(raw_data_entry[:cc]).length
    recipents += to_array(raw_data_entry[:bcc]).length
    recipents == 1 ? ONE2ONE : ONE2MANY
  end

  # Return INITIATE, REPLY or FORWARD
  def find_email_relation(raw_data_entry)
    return REPLY if raw_data_entry[:subject] =~ /^(R|r)(E|e): .*$/
    return FORWARD if raw_data_entry[:fwd]
    INITIATE
  end

  # Return interaction_type by multiplicity, email_relation, recipient_type
  def get_interaction_type(multiplicity, email_relation, recipient_type)
    relation_type = RULES_TABLE.select do |int_type|
      int_type[:multiplicity] == multiplicity &&
        int_type[:email_relation] == email_relation &&
        int_type[:recipient_type] == recipient_type
    end
    relation_type[0][:interaction_type]
  end

  # Return array of [{sender, :recipent, :interaction_type}, ...]
  def convert_relations_to_arr(sender, recipents, multiplicity, email_relation)
    res = []
    recipient_type = 0
    recipents.each do |recipents_arr|
      # interaction_type = get_interaction_type(multiplicity, email_relation, recipient_type) ASAF BYEBUG
      interaction_type = -1
      recipents_arr.each do |recipent|
        res << { sender: sender, recipent: recipent, interaction_type: interaction_type }
      end
      recipient_type += 1
    end
    res
  end

  def convert_emails_to_employee_ids(emails, company_id)
    return nil if !emails || emails.empty?
    res = email_to_employee_id emails, company_id
    return res
  end

  def convert_emails_array_to_employee_ids(emails, company_id)
    res =  []
    emails_arr = to_array(emails)
    emails_arr.each do |email|
      emp_id = email_to_employee_id email, company_id
      if emp_id
        res << emp_id
      else
        puts "convert_emails_to_employee_ids: Failed to find employee by'#{email}'"
      end
    end
    return res
  end

  ## Needed because the notation: "{a,b,c}" is automatically converted to array in postgres
  ## but not in sql server
  def to_array(arg)
    return arg if arg.is_a?(Array)
    is_valid_format = (arg[0] == '{' && arg[-1] == '}') || (arg[0] == '[' && arg[-1] == ']')
    return [] unless is_valid_format
    return arg[1..-2].split(',')
  end

  def email_to_employee_id(email, company_id)
    cache_key = "email_to_employee_id-company_id-#{company_id}i_email-#{email}"
    cached_id = cache_read(cache_key)
    return cached_id unless cached_id.nil?

    email = email.tr('"', '').strip
    employee_id = Employee.find_by(email: email.downcase).try(:id) || EmployeeAliasEmail.find_by(email_alias: email).try(:employee_id)
    if employee_id.nil?
      return nil if in_comany_doamin_list(email, company_id)

      cache_key_other = 'employee-other@mail.com'
      employee = cache_read(cache_key_other)
      if employee.nil?
        employee = Employee.find_by(email: 'other@mail.com')
        if employee.nil?
          employee = Employee.create!(
            email: 'other@mail.com',
            first_name: 'other',
            last_name: 'other',
            company_id: company_id,
            external_id: SecureRandom.hex
          )
        end
        cache_write(cache_key_other, employee)
      end
      employee_id = employee.try(:id)
    end
    cache_write(cache_key, employee_id)
    return employee_id
  end

  def in_comany_doamin_list(email, company_id)
    domain_list = Company.domains(company_id)
    domaim_from_email = email.split('@').last
    domain_list.each do |domain|
      current_domain = domain.domain
      return true if domaim_from_email == current_domain
    end
    false
  end
end
