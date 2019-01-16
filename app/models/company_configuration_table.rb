include CdsUtilHelper

class CompanyConfigurationTable < ActiveRecord::Base
  LOCALE             = 'LOCALE'
  DEFAULT_LOCALE     = 'en'
  INVESTIGATION_MODE = 'INVESTIGATION_MODE'
  DISPLAY_EMAILS     = 'DISPLAY_EMAILS'
  DISPLAY_FIELD_IN_QUESTIONNAIRE = 'display_field_in_questionnaire'
  MAX_EMPS_IN_MAP    = 'MAX_EMPS_IN_MAP'

  INCOMING_EMAIL_TO_TIME_DEFAULT = (1.0 / 120).round(2)  ## In hours
  OUTGOING_EMAIL_TO_TIME_DEFAULT = (1.0 / 4 ).round(2)  ## In hours
  INCOMING_EMAIL_TO_TIME_KEY = 'INCOMING_EMAIL_TO_TIME_KEY'
  OUTGOING_EMAIL_TO_TIME_KEY = 'OUTGOING_EMAIL_TO_TIME_KEY'
  MAX_EMPS_IN_MAP_DEFAULT = 100

  MAX_LOGIN_ATTMEPTS = 5
  LOCK_TIME_AFTER_MAX_LOGIN_ATTEMPTS = 300
  HIDE_EMPLOYEES     = 'hide_employee_names'
  MIN_EMPS_IN_GROUP_FOR_ALGORITHMS = 'MIN_EMPS_IN_GROUP_FOR_ALGORITHMS'
  PROCESS_MEETINGS = 'process_meetings'

  belongs_to :company, foreign_key: 'comp_id'

  #############################################################################
  ## Catch method calls which look like this: get_some_name(cid=nil) where
  ## some_name is the name of a configuration parameter in this table.
  ## From here we try to capitalize the param and look for it in the database.
  ## First with a company_id, if exists, and if not found then without it.
  #############################################################################
  def method_missing(m, *a)
    raise "Unknow method: #{m}" if !m.to_s.starts_with?('get_')
    cid = !a.nil? ? a[0] : nil
    param_name = m[4..-1].upcase
    ret = CompanyConfigurationTable.where(key: param_name, comp_id: cid) if cid
    ret = (ret.nil? ? CompanyConfigurationTable.where(key: param_name, comp_id: -1) : nil)
    raise "Configuration parameter: #{param_name} not found in company_configuration_table" if ret.nil?
    return ret.last.value
  end

  def self.getKey(key, company_id=nil)
    val = CompanyConfigurationTable.where(key: key, comp_id: company_id).last.try(:value) if !company_id.nil?
    return val if val
    return CompanyConfigurationTable.where(key: key, comp_id: -1).last.try(:value)
  end

  def self.get_company_locale(cid=-1)
    return DEFAULT_LOCALE if cid == -1
    entry = CompanyConfigurationTable.where(comp_id: cid, key: LOCALE).first
    return (entry.nil? ? DEFAULT_LOCALE : entry.value)
  end

  def self.should_display_emails?
    entry = CompanyConfigurationTable.where(comp_id: -1, key: DISPLAY_EMAILS)
    return false if entry.nil?
    return false if entry.first.nil?
    ret = entry.first.value
    return (ret == 'true' || ret == 't')
  end

  def self.is_investigation_mode?
    cache_key = "CompanyConfigurationTable-#{INVESTIGATION_MODE}"
    return CdsUtilHelper::read_or_calculate_and_write(cache_key) do
      is_investigation_mode_configured_in_db?
    end
  end

  def self.hide_employee_names?(cid = -1)
    entry = CompanyConfigurationTable.where(comp_id: cid, key: HIDE_EMPLOYEES)
    return false if entry.nil?
    return false if entry.first.nil?
    ret = entry.first.value
    return (ret == 'true' || ret == 't')
  end

  private

  def self.is_investigation_mode_configured_in_db?
    entry = CompanyConfigurationTable.where(comp_id: -1, key: INVESTIGATION_MODE)
    return false if entry.nil?
    return false if entry.first.nil?
    ret = entry.first.value
    return (ret == 'true' || ret == 't')
  end

  def self.display_field_in_questionnaire(cid=nil)
    ret = 'role'
    entry = nil
    if !cid.nil?
      entry = CompanyConfigurationTable.where(comp_id: cid, key: DISPLAY_FIELD_IN_QUESTIONNAIRE)
    end
    if entry.nil? || entry.first.nil?
      entry = CompanyConfigurationTable.where(comp_id: -1, key: DISPLAY_FIELD_IN_QUESTIONNAIRE)
    end
    return ret if entry.nil?
    return ret if entry.first.nil?
    ret = entry.first.value
    raise "Value: #{ret} is not permitted for key: #{DISPLAY_FIELD_IN_QUESTIONNAIRE}" if ret != 'role' && ret != 'job_title'
    return ret
  end

  def self.incoming_email_to_time
    ret = INCOMING_EMAIL_TO_TIME_DEFAULT
    entry = CompanyConfigurationTable.where(comp_id: -1, key: INCOMING_EMAIL_TO_TIME_KEY)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value
  end

  def self.outgoing_email_to_time
    ret = OUTGOING_EMAIL_TO_TIME_DEFAULT
    entry = CompanyConfigurationTable.where(comp_id: -1, key: OUTGOING_EMAIL_TO_TIME_KEY)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value
  end

  def self.max_emps_in_map
    ret = MAX_EMPS_IN_MAP_DEFAULT
    entry = CompanyConfigurationTable
              .where(comp_id: -1, key: MAX_EMPS_IN_MAP)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value.to_i
  end

  def self.max_login_attempts
    ret = MAX_LOGIN_ATTMEPTS
    entry = CompanyConfigurationTable
              .where(comp_id: -1, key: MAX_LOGIN_ATTMEPTS)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value
  end

  ## Time to wait after max attempts was exceeded in seconds
  def self.lock_time_after_max_login_attempts
    ret = LOCK_TIME_AFTER_MAX_LOGIN_ATTEMPTS
    entry = CompanyConfigurationTable
              .where(comp_id: -1, key: LOCK_TIME_AFTER_MAX_LOGIN_ATTEMPTS)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value
  end


  ## Some algorithms will ignore groups having less employees
  def self.min_emps_in_group_for_algorithms
    ret = 10
    entry = CompanyConfigurationTable
              .where(comp_id: -1, key: MIN_EMPS_IN_GROUP_FOR_ALGORITHMS)
    return ret if entry.nil?
    return ret if entry.first.nil?
    return entry.first.value.to_i
  end

  def self.process_meetings?(cid)
    pm = CompanyConfigurationTable.find_by(comp_id: cid, key: PROCESS_MEETINGS)
    if pm.nil?
      pm = CompanyConfigurationTable.find_by(comp_id: -1, key: PROCESS_MEETINGS)
    end
    return pm.try(:value) == 'true'
  end
end
