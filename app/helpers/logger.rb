# frozen_string_literal: true
require './app/helpers/app_config.rb'

module Util


  @is_trace_level = nil
  @should_write_to_event_log = nil

  def self.should_write_to_event_log?(cid)
    if @should_write_to_event_log.nil?
      @should_write_to_event_log = (CollConfig.new(cid).write_to_event_log == 'true')
    end
    return @should_write_to_event_log
  end

  def self.info(message, cid=nil)
    msg = "COLLECTOR(#{cid})-INFO - #{message}"
    puts msg
    return if !Util.should_write_to_event_log?(cid)
    EventLog.log_event(cid, msg)
  end

  def self.error(message, cid=nil)
    msg = "COLLECTOR(#{cid})-ERROR - #{message}"
    puts msg
    return if !Util.should_write_to_event_log?(cid)
    EventLog.log_event(cid, msg)
  end

  def self.log_error(message, cid=nil)
    msg = "COLLECTOR(#{cid})-ERROR - #{message}"
    puts msg
  end

  def self.heading(message, cid=nil)
    msg = "COLLECTOR(#{cid})-HEADING - #{message}"
    puts "----------------------------------------"
    puts msg
    puts "----------------------------------------"
    EventLog.log_event(cid, msg)
  end

  def self.trace(message, cid=nil)
    if @is_trace_level.nil?
      @is_trace_level = (CollConfig.new(cid).log_level == 'trace')
    end
    return if !@is_trace_level
    msg = "COLLECTOR(#{cid})-TRACE - #{message}"
    puts msg
  end

  ##################################################################################
  # Strings encryption
  ##################################################################################
  def self.encrypt(text)
    return if text.nil?
    len   = ActiveSupport::MessageEncryptor.key_len
    salt  = SecureRandom.hex len
    key   = ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base).generate_key salt, len
    crypt = ActiveSupport::MessageEncryptor.new key
    encrypted_data = crypt.encrypt_and_sign text
    return "#{salt}$$#{encrypted_data}"
  end

  def self.decrypt(text)
    return if text.nil?
    salt, data = text.split("$$")
    len   = ActiveSupport::MessageEncryptor.key_len
    key   = ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base).generate_key(salt, len)
    crypt = ActiveSupport::MessageEncryptor.new(key)
    return crypt.decrypt_and_verify(data)
  end
end
