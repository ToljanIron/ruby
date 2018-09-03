# frozen_string_literal: true

module Util

  @is_trace_level = nil
  @should_write_to_event_log = true

  def self.get_log_level
    ret = CompanyConfigurationTable.getKey('APP_LOG_LEVEL', -1)
    return ret || 'trace'
  end

  def self.should_write_to_event_log?(cid)
    if @should_write_to_event_log.nil?
      @should_write_to_event_log = true
    end
    return @should_write_to_event_log
  end

  def self.info(message, cid=nil)
    msg = "COLLECTOR(#{cid})-INFO - #{message}"
    puts msg
    return if !Util.should_write_to_event_log?(cid)
    EventLog.log_event(company_id: cid, message: msg)
  end

  def self.error(message, cid=nil)
    msg = "COLLECTOR(#{cid})-ERROR - #{message}"
    puts msg
    return if !Util.should_write_to_event_log?(cid)
    EventLog.log_event(company_id: cid, message: msg)
  end

  def self.log_error(message, cid=nil)
    msg = "COLLECTOR(#{cid})-ERROR - #{message}"
    puts msg
  end

  def self.heading(message, cid=nil)
    msg = "COLLECTOR(#{cid})-HEADING - #{message}"
    puts.info "----------------------------------------"
    puts.info msg
    puts.info "----------------------------------------"
    EventLog.log_event(company_id: cid, message: msg)
  end

  def self.trace(message, cid=nil)
    if @is_trace_level.nil?
      @is_trace_level = (get_log_level == 'trace')
    end
    return if !@is_trace_level
    msg = "COLLECTOR(#{cid})-TRACE - #{message}"
    puts msg
  end
end
