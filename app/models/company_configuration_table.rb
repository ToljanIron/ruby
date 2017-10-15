include CdsUtilHelper

class CompanyConfigurationTable < ActiveRecord::Base
  LOCALE             = 'LOCALE'
  DEFAULT_LOCALE     = 'en'
  INVESTIGATION_MODE = 'INVESTIGATION_MODE'
  DISPLAY_EMAILS     = 'DISPLAY_EMAILS'

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
end
