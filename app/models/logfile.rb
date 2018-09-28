# frozen_string_literal: true
class Logfile < ActiveRecord::Base

  has_many :raw_data_entry

  enum state: [
    :new_file,
    :processed,
    :error1,
    :error2,
    :error3,
    :badfile
  ]
  enum file_type: [:na, :exchange]

  def self.change_state(filename, cid, state)
    log_record = Logfile.find_by(file_name: filename, company_id: cid)
    raise "File: #{filename} from company: #{cid} not found" if log_record.nil?
    log_record.update!(state: state)
  end

  def self.create_new_file(company_id, file_name)
    lf = Logfile.create!(company_id: company_id, file_name: file_name)
    return lf.id
  end

  def self.create_bad_file(company_id, file_name, error_msg)
    lf = Logfile.find_by(company_id: company_id,file_name: file_name)
    lf = Logfile.create!(
      company_id: company_id,
      file_name: file_name
    ) if lf.nil?

    lf.update(
      error_message: error_msg,
      state: :badfile
    )
    return lf.id
  end

  def self.file_is_processed?(file_name, cid)
    state = Logfile.find_by(company_id: cid, file_name: file_name).try(:state)
    return (state == 'processed')
  end
end
