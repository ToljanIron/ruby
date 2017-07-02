require './lib/tasks/modules/email_properities_translator.rb'
require './app/helpers/email_snapshot_data_helper.rb'
include EmailPropertiesTranslator
include EmailSnapshotDataHelper

module CreateSnapshotHelper
  require 'date'

  TYPE_WEEK  = 0
  TYPE_MONTH = 1
  TYPE_YEAR  = 2

  OUT_OF_DOMAIN_TRANSACTIONS_TYPE = 0

  def create_company_snapshot_by_weeks(cid, date, create_measures_snapshots = true)
    end_date = calculate_end_date_of_snapshot(date, cid)
    name = create_snapshot_by_week_name(end_date, cid)
    if !exist_snapshot?(cid, name)
      snapshot = Snapshot.create(name: name, snapshot_type: nil, timestamp: end_date, company_id: cid)
    else
      snapshot = Snapshot.find_by(company_id: cid, name: name, snapshot_type: nil)
    end

    sid = snapshot.id
    prev_sid = Snapshot.last_snapshot_of_company(cid)

    puts "Creating groups snapshot"
    Group.create_snapshot(cid, prev_sid, sid)

    puts "Creating employees snapshot"
    Employee.create_snapshot(cid, prev_sid, sid)

    return snapshot unless create_measures_snapshots
    puts "Going to create a snapshot for sid: #{sid}, end_date: #{end_date}"
    create_emails_for_weekly_snapshots(cid, snapshot.id, end_date)

    puts "Duplicating emails"
    duplicate_network_snapshot_data_for_weekly_snapshots(cid, sid)

    puts "In calc_meaningfull_emails"
    EmailSnapshotDataHelper.calc_meaningfull_emails(sid)

    if CompanyConfigurationTable.find_by(comp_id: cid, key: 'process_meetings').try(:value) == 'true'
      puts "Creating meetings snapshot"
      start_date = end_date - get_period_of_weeks(cid).to_i.week
      MeetingsHelper.create_meetings_for_snapshot(sid, start_date, end_date)
    end

    puts "Done create_company_snapshot_by_weeks"
    return snapshot
  end

  def create_snapshot_by_week_name(end_date ,cid)
    return end_date.strftime('%Y-%U') if get_company_start_day_of_week(cid) == 7
    return end_date.strftime('%Y-%W')
  end

  def get_company_start_day_of_week(cid)
    company_start_day_of_week = CompanyConfigurationTable.where(comp_id: cid, key: 'start_day_of_week').first
    if !company_start_day_of_week.nil?
      company_start_day_of_week = company_start_day_of_week.value
    else
      company_start_day_of_week = 7
    end
    return company_start_day_of_week
  end

  def get_period_of_weeks(cid)
    company_period_of_weeks = CompanyConfigurationTable.where(comp_id: cid, key: 'period_of_weeks').first
    if !company_period_of_weeks.nil?
      company_period_of_weeks = company_period_of_weeks.value
    else
      company_period_of_weeks = 4
    end
    return company_period_of_weeks
  end

  def calculate_end_date_of_snapshot(date, company_id)
    date = Date.parse(date)
    company_start_day_of_week = get_company_start_day_of_week(company_id)
    date -= 1.day while date.cwday != company_start_day_of_week.to_i
    return date
  end

  def create_emails_for_weekly_snapshots(cid, sid, end_date)
    start_date = end_date - get_period_of_weeks(cid).to_i.week
    puts "create_emails_for_weekly_snapshots - start_date: #{start_date}"
    if ENV['e2e_test']
      raw_data_entries = RawDataEntry.where(company_id: cid)
    else
      raw_data_entries = RawDataEntry.where(company_id: cid, date: start_date..end_date)
    end
    puts "Found #{raw_data_entries.length} raw entries"
    puts "create snapshot - prepare"
    company = Snapshot.find(sid).company_id
    network = NetworkSnapshotData.emails(company)
    db_records = NetworkSnapshotData.where(snapshot_id: sid, network_id: network)
    puts "create snapshot - delete old records"
    db_records.delete_all
    company_employee_emails = Employee.by_snapshot(sid).pluck(:email)
    company_employee_emails_hash = Hash.new(company_employee_emails.length)
    company_employee_emails.each { |e| company_employee_emails_hash[e] = 1 }
    puts "create snapshot - get existing domains"
    raw_data_entries_dup = raw_data_entries.dup
    puts "create snapshot - get existing domains"
    in_domain_raw_data_entries_res = in_domain_emails_filter(raw_data_entries, company_employee_emails_hash, cid)
    in_domain_raw_data_entries                      = in_domain_raw_data_entries_res[0]
    in_domain_raw_data_entries_with_external_sender = in_domain_raw_data_entries_res[1]
    puts "create snapshot - get non-existing domains"
    out_of_domain_transactions = out_of_domain_emails_filter(raw_data_entries_dup, company_employee_emails_hash)
    puts "create snapshot - process out of domain trasactions"
    process_out_of_domain_transactions(out_of_domain_transactions, sid)
    existing_records_arr = []
    puts "create snapshot - calculate email relations and subjects"
    ii = 0
    in_domain_raw_data_entries.each do |rde|
      ii += 1
      hashed_rde = hash_raw_data_entry(rde)
      existing_records = EmailPropertiesTranslator.process_email(hashed_rde, cid, sid)
      existing_records_arr = existing_records_arr.concat(existing_records)
      puts "Went over #{ii} records" if (ii % 2000 == 0)
    end
    puts "Going over senders from external_domains"
    process_in_domain_transactions_with_external_sender(in_domain_raw_data_entries_with_external_sender, sid)
    entries_count = existing_records_arr.count
    email_network_id = NetworkName.where(company_id: cid, name: 'Communication Flow')[0].id
    puts "create snapshot - write to network_snapshot_data"
    (0..entries_count/1000).each do |i|
      puts "Writing to network_snapshot_data batch number: #{i} out of #{entries_count/1000}"
      foffset = i * 1000
      toffset = (i == entries_count/1000 ? entries_count : ((i+1) * 1000) - 1)
      columns = '(value, snapshot_id, network_id, company_id, from_employee_id, to_employee_id, message_id, multiplicity, from_type, to_type, communication_date)'
      values = existing_records_arr[foffset..toffset].map do |r|
        "(1,#{sid},#{email_network_id},#{cid},#{r[:from_employee_id]},#{r[:to_employee_id]},'#{r[:message_id]}',#{r[:multiplicity]},#{r[:from_type]},#{r[:to_type]},'#{r[:email_date].to_time.strftime('%Y-%m-%d %H:%M:%S.%L')}')"
      end
        values = values.join(', ')
      return if values.empty?
      query = "INSERT INTO network_snapshot_data #{columns} VALUES #{values}"
      NetworkSnapshotData.connection.execute(query)
    end
    puts "Wrote #{entries_count} records to network_snapshot_data"

    puts "create snapshot - update raw_data_entries"
    raw_data_entries.update_all(processed: true)
    puts "create snapshot done"
  end

  def in_domain_emails_filter(raw_data_entries, company_employee_emails, cid)
    sender_in_domain = []
    sender_not_in_domain = []
    company_domains = Domain.where(company_id: cid).pluck(:domain)

    raw_data_entries.each do |rde|
      rde.to  = to_array(rde.to).select  { |e| company_employee_emails.key?(e) }
      rde.cc  = to_array(rde.cc).select  { |e| company_employee_emails.key?(e) }
      rde.bcc = to_array(rde.bcc).select { |e| company_employee_emails.key?(e) }
      sender_is_in_domain = email_is_in_company?(rde.from, company_domains)
      sender_in_domain     << rde if sender_is_in_domain
      sender_not_in_domain << rde if !sender_is_in_domain
    end
    return [sender_in_domain, sender_not_in_domain]
  end

  def email_is_in_company?(email, company_domains)
      domain = email.split(/\@/)[1].downcase
    return company_domains.include?(domain)
  end

  def out_of_domain_emails_filter(raw_data_entries, company_employee_emails)
    ret = raw_data_entries.each do |rde|
      rde.to  = to_array(rde.to).select  { |e| !company_employee_emails.key?(e) }
      rde.cc  = to_array(rde.cc).select  { |e| !company_employee_emails.key?(e) }
      rde.bcc = to_array(rde.bcc).select { |e| !company_employee_emails.key?(e) }
    end
    return ret
  end

  def process_in_domain_transactions_with_external_sender(raw_data_entries, sid)
    cid = Snapshot.where(id: sid).first.try(:company_id)
    overlay_entity_type = OverlayEntityType.find_or_create_by(overlay_entity_type: 0, name: 'external_domains')
    emps = Employee.by_snapshot(sid)
    emps_hash = Hash.new(emps.length)
    emps.map { |e| emps_hash[e.email] = e.id }
    raw_data_entries.each do |rde|
      from_email = rde.from.tr("\"", '')
      rdeto  = to_array(rde.to)
      rdecc  = to_array(rde.cc)
      rdebcc = to_array(rde.bcc)
      rdeto.each  { |rec|  handle_from_external_to_internal(from_email, rec, sid, overlay_entity_type, cid, emps_hash) }
      rdecc.each  { |rec|  handle_from_external_to_internal(from_email, rec, sid, overlay_entity_type, cid, emps_hash) }
      rdebcc.each { |rec|  handle_from_external_to_internal(from_email, rec, sid, overlay_entity_type, cid, emps_hash) }
    end
  end

  def handle_from_external_to_internal(from_email, to_email, sid, overlay_entity_type, cid, emps_hash)
    from_domain_name = to_email.split(/\@/)[1].downcase
    from_domain_name = from_domain_name.tr("\"", '')
    o_e_group = OverlayEntityGroup.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, name: from_domain_name)
    overlay_entity = OverlayEntity.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, overlay_entity_group_id: o_e_group.id, name: from_email)
    to_id = emps_hash[to_email]
    a = OverlaySnapshotData.find_by(snapshot_id: sid, from_id: overlay_entity.id, from_type: :from_overlay_entity, to_id: to_id, to_type: :to_employee)
    if a.nil?
      OverlaySnapshotData.create(snapshot_id: sid, from_id: overlay_entity.id, from_type: :from_overlay_entity, to_id: to_id, to_type: :to_employee, value: 1)
    else
      a.value = a.value + 1
      a.save!
    end
  end

  def process_out_of_domain_transactions(raw_data_entries, sid)
    cid = Snapshot.where(id: sid).first.try(:company_id)
    emps = Employee.by_snapshot(sid)
    emps_hash = Hash.new(emps.length)
    emps.map { |e| emps_hash[e.email] = e }
    overlay_entity_type = OverlayEntityType.find_or_create_by(overlay_entity_type: 0, name: 'external_domains')
    raw_data_entries.each do |rde|
      emp = emps_hash[rde.from] if emps_hash.key?(rde.from)
      rdeto  = to_array(rde.to)
      rdecc  = to_array(rde.cc)
      rdebcc = to_array(rde.bcc)
      next if emp.nil? || (rde.to.empty? && rde.cc.empty? && rde.bcc.empty?)
      rdeto.each { |rec|  handle_employee_attribute(emp, rec, sid, overlay_entity_type, cid) }
      rdecc.each { |rec|  handle_employee_attribute(emp, rec, sid, overlay_entity_type, cid) }
      rdebcc.each { |rec| handle_employee_attribute(emp, rec, sid, overlay_entity_type, cid) }
    end
  end

  def handle_employee_attribute(emp, rec, sid, overlay_entity_type, cid)
    to_domain_name = rec.split(/\@/)[1].downcase
    to_domain_name = to_domain_name.tr("\"", '')
    rec = rec.tr("\"", '')

    o_e_group = OverlayEntityGroup.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, name: to_domain_name)
    OverlayEntityConfiguration.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid)
    overlay_entity = OverlayEntity.find_or_create_by(overlay_entity_type_id: overlay_entity_type.id, company_id: cid, overlay_entity_group_id: o_e_group.id,name: rec.downcase)
    a = OverlaySnapshotData.find_by(snapshot_id: sid, from_id: emp.id, from_type: :from_employee, to_id: overlay_entity.id, to_type: :to_overlay_entity)
    if a.nil?
      OverlaySnapshotData.create(snapshot_id: sid, from_id: emp.id, from_type: :from_employee, to_id: overlay_entity.id, to_type: :to_overlay_entity, value: 1)
    else
      a.value = a.value + 1
      a.save!
    end
  end

  ## Needed because the notation: "{a,b,c}" is automatically converted to array in postgres
  ## but not in sql server
  def to_array(arg)
    return arg if arg.is_a?(Array)
    is_valid_format = (arg[0] == '{' && arg[-1] == '}') || (arg[0] == '[' && arg[-1] == ']')
    return [] if !is_valid_format
    return arg[1..-2].split(',')
  end

  def convert_monthly_snapshot_to_weekly_snapshot(company_id, snapshot_id)
    snapshots = snapshot_id == -1 ? Snapshot.where(company_id: company_id) : Snapshot.where(id: snapshot_id, company_id: company_id)
    snapshots.each do |s|
      monthly_date = Date.new(s.timestamp.year, s.timestamp.month)
      (1..5).each do |i|
        create_company_snapshot_by_weeks(company_id, monthly_date.strftime('%y-%m-%d'))
        monthly_date += 1.week
      end
    end
  end

  def duplicate_network_snapshot_data_for_weekly_snapshots(company_id, sid)
    return true if (Snapshot.where(company_id: company_id).count == 1)
    emails_network_id = NetworkName.get_emails_network(company_id)
    previous_sid = Snapshot.find(sid).get_the_snapshot_before_the_last_one.id
    ActiveRecord::Base.connection.execute(
      "insert into network_snapshot_data
         (snapshot_id, network_id, company_id, from_employee_id, to_employee_id, value, original_snapshot_id)
         select #{sid}, network_id, #{company_id}, from_employee_id, to_employee_id, value, #{previous_sid}
           from network_snapshot_data
           where snapshot_id = #{previous_sid} and network_id <> #{emails_network_id}"
    )

    return true

    relevant_network_snapshot_data = NetworkSnapshotData.where(snapshot_id: sid).select { |row| row.original_snapshot.created_at > Time.now - 1.year }
    last_snapshot_network_snapshot_data = NetworkSnapshotData.where(snapshot_id: previous_sid).select { |row| row.original_snapshot.nil? || (row.original_snapshot && row.original_snapshot.created_at > Time.now - 1.year )}
    if relevant_network_snapshot_data.nil? || relevant_network_snapshot_data.empty?
      duplicate_all_the_last_snapshot_data(last_snapshot_network_snapshot_data, sid)
      return true
    end

    relevant_network_snapshot_data.each do |new_data_row|
      next if new_data_row.questionnaire_question_id == -1
      relevant_data = get_relevant_data(new_data_row, last_snapshot_network_snapshot_data)
      if relevant_data.nil?
        next
      else
      decide_which_one_should_be_the_new(new_data_row, relevant_data, sid)
      end
    end

    last_snapshot_network_snapshot_data.each do |old_data_row|
      next if old_data_row.questionnaire_question_id == -1
      new_data_row = get_relevant_data(old_data_row, relevant_network_snapshot_data)
      if new_data_row.nil?
        duplicate_row(old_data_row, sid)
        next
      else
      decide_which_one_should_be_the_new(new_data_row, old_data_row, sid)
      end
    end

    return true
  end

  def duplicate_row(data_row, sid)
    dup_data = data_row.dup
    dup_data.update(snapshot_id: sid, original_snapshot_id: data_row.original_snapshot_id)
    dup_data.save
  end

  def duplicate_all_the_last_snapshot_data(last_snapshot_network_snapshot_data, sid)
    last_snapshot_network_snapshot_data.each do |old_data|
      dup_data = old_data.dup
      dup_data.update(snapshot_id: sid, original_snapshot_id: old_data.original_snapshot_id)
      dup_data.save
    end
  end

  def decide_which_one_should_be_the_new(new_data_row, relevant_data, sid)
    if new_data_row.value == 1
      return true
    else
      is_from_selected_to_in_indipendent_question = get_is_from_selected_to_in_indipendent_question(new_data_row)
      unless is_from_selected_to_in_indipendent_question
        new_data_row.update(value: relevant_data.value, original_snapshot_id: relevant_data.original_snapshot_id)
      end
    end
  end

  def get_is_from_selected_to_in_indipendent_question(new_data_row)
    if new_data_row.questionnaire_question_id == -1 || new_data_row.questionnaire_question_id.nil?
      return true
    end
    relevant_questionnaire_question = new_data_row.questionnaire_question
    relevant_from_questionnaire_participant = relevant_questionnaire_question.questionnaire_participants.where(employee_id: new_data_row.from_employee_id).first
    relevant_to_questionnaire_participant = relevant_questionnaire_question.questionnaire_participants.where(employee_id: new_data_row.to_employee_id).first
    fail 'one of the employees doesnt have questionnaire participant' if relevant_from_questionnaire_participant.nil? || relevant_to_questionnaire_participant.nil?
    relevant_indipendent_questionnaire_question_replies = QuestionnaireQuestion.find_by(order: 1, questionnaire_id: new_data_row.questionnaire_question.questionnaire_id).question_replies
    return relevant_indipendent_questionnaire_question_replies.where( questionnaire_participant_id: relevant_from_questionnaire_participant,
                                                               reffered_questionnaire_participant_id: relevant_to_questionnaire_participant).first.answer == true
  end

  def get_relevant_data(new_data_row, last_snapshot_network_snapshot_data)
    return last_snapshot_network_snapshot_data.select { |row|
      new_data_row.from_employee_id == row.from_employee_id &&
      new_data_row.to_employee_id   == row.to_employee_id &&
      new_data_row.network_id       == row.network_id
    }.first
  end

  private

  def hash_raw_data_entry(raw_data_entry)
    hashed_rde = {}
    hashed_rde[:from] = raw_data_entry.from
    hashed_rde[:to] = raw_data_entry.to
    hashed_rde[:cc] = raw_data_entry.cc
    hashed_rde[:bcc] = raw_data_entry.bcc
    hashed_rde[:message_id] = raw_data_entry.msg_id
    hashed_rde[:fwd] = raw_data_entry.fwd
    hashed_rde[:reply_to_msg_id] = raw_data_entry.reply_to_msg_id
    hashed_rde[:subject] = raw_data_entry.subject
    hashed_rde[:email_date] = raw_data_entry.date
    hashed_rde
  end

  def exist_snapshot?(cid, name, snapshot_type=nil)
    return (Snapshot.where(company_id: cid, name: name, snapshot_type: snapshot_type).size > 0)
  end
end
