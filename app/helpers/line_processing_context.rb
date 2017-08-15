require './lib/tasks/modules/create_snapshot_helper.rb'
include CreateSnapshotHelper
include CdsUtilHelper

module LineProcessingContextClasses
  ########################################## Abstract LineProcessingContext ##########################################
  class LineProcessingContext
    attr_accessor :attrs
    attr_reader   :original_line
    attr_reader   :original_line_number
    attr_reader   :original_csv_type
    attr_accessor :error_log

    def initialize(original_line, original_line_number, company_id, original_csv_type = nil, use_latest_snapshot = false)
      @original_line = original_line
      @original_line_number = original_line_number
      @original_csv_type = original_csv_type
      @attrs = { company_id: company_id }
      @error_log = []
      @sid = Snapshot.last_snapshot_of_company(company_id)
    end

    def create_if_not_existing
    end

    def connect
    end

    def delete
    end

    def log_suffix
      "while processing line ##{original_line_number}: '#{original_line}'"
    end

    def to_s
      "{attrs: #{attrs.to_json}, l: \"#{original_line}\", err: \"#{error_log.join('|')}\""
    end

    def find_or_create_snapshot(company_id, snapshot_name)
      s = CreateSnapshotHelper.create_company_snapshot_by_weeks(company_id, snapshot_name, false)
      return s.id if s
    end
  end
  ########################################## ErrorLineProcessingContext ##########################################
  class ErrorLineProcessingContext < LineProcessingContext
    def initialize(original_line, original_line_number, company_id, csv_type = nil)
      super(original_line, original_line_number, company_id, csv_type)
      @error_log = ["error #{log_suffix}"]
    end
  end

  ########################################## GroupLineProcessingContext ##########################################
  class GroupLineProcessingContext < LineProcessingContext
    def initialize(original_line, original_line_number, company_id, parent_name = nil)
      super(original_line, original_line_number, company_id)
      @parent_name = parent_name
    end

    def create_if_not_existing
      cid = @attrs[:company_id]
      fail unless cid && !Company.where(id: cid).empty?
      sid = Snapshot.last_snapshot_of_company(cid)
      g = Group.find_or_create_by(
        company_id: cid,
        external_id: @attrs[:external_id],
        snapshot_id: sid
      )

      g.name = @attrs[:name]
      g.english_name =  @attrs[:english_name]
      g.save!
      return if g.persisted?
    rescue => e
      @error_log << "unable to create group with external_id #{@attrs[:external_id]} in snapshot: #{sid}. #{e}, #{log_suffix}"
    end

    def connect
      begin
        cid = @attrs[:company_id]

        g = Group.find_by(company_id: cid, external_id: @attrs[:external_id], snapshot_id: @sid)

        g.update(name: @attrs[:name]) if (@attrs[:name] && !g.nil? && g.name != @attrs[:name])
        g.update(color_id: choose_random_color) if (!g.nil? && g.color_id.nil?)

        parent = Group.find_by(company_id: cid, external_id: @attrs[:parent_external_id], snapshot_id: @sid)

        ## Do this because in some cases parent groups may be specified in terms of their names
        if parent.nil?
          parent = Group.find_by(company_id: cid, name: @attrs[:parent_external_id], snapshot_id: @sid)
        end
        g.update( parent_group_id: parent.id) if !parent.nil?
      rescue => ex
        puts "EXCEPTION: #{ex.message}"
        puts ex.backtrace
        @error_log << ex.message + " - unable to connect group #{@attrs[:name]} with parent group #{@parent_name} in snapshot: #{sid}, #{log_suffix}"
        return
      end
      return
    end

    def delete
      return unless @attrs[:delete]
      begin
        cid = @attrs[:company_id]

        higest_group = Group.find_by(company_id: cid, snapshot_id: @sid, parent_group_id: nil, )
        g = Group.find_by(company_id: cid, snapshot_id: @sid, external_id: @attrs[:external_id])
        child_groups = Group.where(parent_group_id: g.id)
        child_groups.each do |cg|
          cg.update(parent_group_id: higest_group.id)
        end
      rescue => ex
        puts "EXCEPTION: #{ex.message}"
        puts ex.backtrace
        @error_log << ex.message + " - unable to delete group #{@attrs[:name]} in snapshot: #{sid} , #{log_suffix}"
      end
    end
  end
  ########################################## EmployeeLineProcessingContext ##########################################
  class EmployeeLineProcessingContext < LineProcessingContext
    def initialize(original_line, original_line_number, company_id, satellite_tables_attrs = {})
      super(original_line, original_line_number, company_id)
      @satellite_tables_attrs = satellite_tables_attrs
    end

    def create_if_not_existing
      begin
        fail 'can not find company_id'  if @attrs[:company_id].nil?
        fail "can not find company with id: #{@attrs[:company_id]}" if Company.where(id: @attrs[:company_id]).empty?
        #fail 'email is empty' if @attrs[:email].empty?
        return if @attrs[:email].nil? || @attrs[:email].empty?
        unless @attrs[:date_of_birth].nil? || @attrs[:date_of_birth].empty?
          unless check_date(@attrs[:date_of_birth])
           puts "ERROR: date_of_birth: #{@attrs[:date_of_birth]} is invalid"
           @attrs.delete(:date_of_birth)
          end
        end
        unless @attrs[:work_start_date].nil? || @attrs[:work_start_date].empty?
          unless check_date(@attrs[:work_start_date])
            puts 'ERROR: work_start_date is invalid'
            @attrs.delete(:work_start_date)
          end
        end

        hash = Employee.build_from_hash(@attrs)
      rescue => ex
        @error_log << ex.message + " unable to create employee with external id #{@attrs[:external_id]} - #{ex}, #{log_suffix}"
        puts ex.backtrace
        return
      end

      e = hash.delete(:employee)
      if e.valid?
        errors = hash.delete(:employee) || []
        errors.each do |err|
          @error_log << "unknown employee attribute #{err}, #{log_suffix}"
        end
        @satellite_tables_attrs = hash
        e.save
        return
      end
      @error_log << "unable to create employee with external id #{@attrs[:external_id]}, #{log_suffix}"
    end

    def check_date(date)
      date_regex = /(19\d{2}|20[0-5]\d)-(0\d{1}|1[0-2]|[1-9])-[0-3]*\d/
      return (date =~ date_regex) == 0
    end

    def connect
      begin
        e = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:external_id])
        return unless e
        connect_offices e
        connect_qualifications e
        connect_group e
        connect_marital_status e
        connect_job_title e
        connect_role e
        connect_rank e
        add_color e
      rescue => ex
        @error_log << ex.message + " unable to create employee with external id #{@attrs[:external_id]} - #{ex}, #{log_suffix}"
        puts ex.backtrace
        return
      end
    end

    def delete
      e = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:external_id])
      e.delete if e
    end

    def connect_alias_emails(employee)
      return if @satellite_tables_attrs[:alias_emails] == ''
      emails = @satellite_tables_attrs[:alias_emails].split('#')
      emails.each do |email|
        eae = EmployeeAliasEmail.build_from_email email.strip
        if eae
          eae.employee_id = employee.id
          eae.save
        else
          @error_log << "unable to connect employee with external id '#{@attrs[:external_id]}' with alias email '#{email}', #{log_suffix}"
        end
      end
    end

    def connect_offices(employee)
      return nil if @satellite_tables_attrs[:office_address] == ''
      office = Office.find_by(name: @satellite_tables_attrs[:office_address], company_id: employee.company_id)
      unless office.nil?
        employee.office_id = office.id
        employee.save
        return
      end
      new_office = Office.create(name: @satellite_tables_attrs[:office_address], company_id: employee.company_id)
      employee.office_id = new_office.id
      employee.save
    end

    def connect_qualifications(_employee)
    end

    def connect_group(employee)
      return nil if @satellite_tables_attrs[:group_name].nil?
      g = Group.find_by(name: @satellite_tables_attrs[:group_name], snapshot_id: @sid)
      g = Group.find_by(external_id: @satellite_tables_attrs[:group_name], snapshot_id: @sid) if g.nil?
      if g
        employee.group_id = g.id
        employee.save
        return
      end
      @error_log << "unable to connect employee with external id '#{@attrs[:external_id]}' can't find group by name '#{@attrs[:group_name]}', #{log_suffix}"
    end

    def connect_rank(employee)
      return nil if @satellite_tables_attrs[:rank] == ''
      rank = Rank.find_by(name: @satellite_tables_attrs[:rank])
      return unless rank
      employee.rank_id = rank.id
      employee.save
      return
    end

    def connect_marital_status(employee)
      return nil if @satellite_tables_attrs[:marital_status] == ''
      ms = MaritalStatus.find_by(name: @satellite_tables_attrs[:marital_status])
      return unless ms
      employee.marital_status_id = ms.id
      employee.save
    end

    def connect_job_title(employee)
      return nil if @satellite_tables_attrs[:job_title] == ''
      jt = JobTitle.find_by(name: @satellite_tables_attrs[:job_title], company_id: employee.company_id)
      unless jt.nil?
        employee.job_title_id = jt.id
        employee.save
        return
      end
      new_job = JobTitle.create(name: @satellite_tables_attrs[:job_title], company_id: employee.company_id)
      employee.job_title_id = new_job.id
      employee.save
    end

    def connect_role(employee)
      return nil if @satellite_tables_attrs[:role] == ''
      role = Role.find_by(name: @satellite_tables_attrs[:role], company_id: employee.company_id)
      unless role.nil?
        employee.company_id
        employee.role_id = role.id
        employee.save
        return
      end
      new_role = Role.create(name: @satellite_tables_attrs[:role], company_id: employee.company_id, color_id: choose_random_color)
      employee.role_id = new_role.id
      employee.save
    end

    def add_color(employee)
      employee.color_id = choose_random_color
      employee.save
    end
  end

  ########################################## RelationLineProcessingContext ##########################################
  class RelationLineProcessingContext < LineProcessingContext
    def create_if_not_existing
      fail if @attrs[:company_id].nil? || Company.where(id: @attrs[:company_id]).empty?
      return if @attrs[:delete]
      manager = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:manager_external_id])
      employee = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:employee_external_id])
      relation = EmployeeManagementRelation.find_by(manager_id: manager.id, employee_id: employee.id)
      if relation
        relation.update(relation_type: @attrs[:relation_type])
        return
      end
      EmployeeManagementRelation.create(
        manager_id: manager.id,
        employee_id: employee.id,
        relation_type: @attrs[:relation_type]
        )
      return
    rescue => e
      @error_log << "unable to create managment relation. #{e}, #{log_suffix}"
    end

    def delete
      manager_id = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:manager_external_id])
      employee_id = Employee.find_by(snapshot_id: @sid, external_id: @attrs[:employee_external_id])
      relation_type = @attrs[:relation_type]
      return unless manager_id && employee_id && relation_type
      r = EmployeeManagementRelation.find_by(manager_id: manager_id, employee_id: employee_id, relation_type: relation_type)
      r.delete if r
    end
  end

  def context_list_errors(context_list)
    context_list.map { |c| c.error_log }.flatten
  end

  ########################################## V2LineProcessingContext ##########################################
  class NetworkLineProcessingContext < LineProcessingContext
    def create_if_not_existing
      fail if @attrs[:company_id].nil? || @attrs[:csv_type].nil? || Company.where(id: @attrs[:company_id]).empty?
      use_latest_snapshot = @attrs[:use_latest_snapshot].nil? ? false : @attrs[:use_latest_snapshot]
      snapshot_time = @attrs.delete(:snapshot)
      sid = use_latest_snapshot ? Snapshot.last_snapshot_of_company(e1[:company_id]) : find_or_create_snapshot(e1[:company_id], snapshot_time)

      e1 = Employee.find_by(snapshot_id: sid, external_id: @attrs[:from_employee_id])
      e2 = Employee.find_by(snapshot_id: sid, external_id: @attrs[:to_employee_id])
      value = @attrs[:value]
      fail if e1[:company_id] != e2[:company_id]

      network_name = NetworkName.find_or_create_by(name: @attrs[:csv_type], company_id: @attrs[:company_id].to_i)
      NetworkSnapshotData.find_or_create_by(
        snapshot_id: sid,
        network_id: network_name.id,
        company_id: @attrs[:company_id].to_i,
        from_employee_id: e1.id,
        to_employee_id: e2.id,
        value: value.to_i,
        questionnaire_question_id: -1,
        original_snapshot_id: sid
      )
    rescue => e
      @error_log << "unable to create NetworkSnapshotData relation. #{e}, #{@attrs}"
      puts "EXCEPTIO: #{e.message[0..1000]}"
      puts e.backtrace
    end
  end
end
