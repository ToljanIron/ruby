include CdsUtilHelper

class CompanyConfigurationTable < ActiveRecord::Base
  LOCALE             = 'LOCALE'
  DEFAULT_LOCALE     = 'en'
  INVESTIGATION_MODE = 'INVESTIGATION_MODE'
  DISPLAY_EMAILS     = 'DISPLAY_EMAILS'
  DISPLAY_FIELD_IN_QUESTIONNAIRE = 'display_field_in_questionnaire'

  belongs_to :company, foreign_key: 'comp_id'

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

  private

  def self.is_investigation_mode_configured_in_db?
    entry = CompanyConfigurationTable.where(comp_id: -1, key: INVESTIGATION_MODE)
    return false if entry.nil?
    return false if entry.first.nil?
    ret = entry.first.value
    return (ret == 'true' || ret == 't')
  end

  def self.display_field_in_questionnaire
    ret = 'role'
    entry = CompanyConfigurationTable.where(comp_id: -1, key: DISPLAY_FIELD_IN_QUESTIONNAIRE)
    return ret if entry.nil?
    return ret if entry.first.nil?
    ret = entry.first.value
    raise "Value: #{ret} is not permitted for key: #{DISPLAY_FIELD_IN_QUESTIONNAIRE}" if ret != 'role' && ret != 'job_title'
    return ret
  end
end
