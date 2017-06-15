module TestCompanySeed
  COMPANY_SIZE = ENV['size'].to_i # expected to be >= 7
  COMPANY_NAME = ENV['name']
  COMPANY_TYPE = ENV['type']
  WITH_SNAPSHOTS = ENV['snapshots']
  NO_CEO = ENV['no_ceo']
  NO_MANAGERS = ENV['no_managers']
  NO_DEP_MANAGERS = ENV['no_dep_managers']
  def self.run_seed
    fail 'no company size was given' unless COMPANY_SIZE > 0
    fail 'no company name was given' unless COMPANY_NAME
    fail 'no company type was given, state type=exchange or type=google' unless %w(exchange google).include? COMPANY_TYPE
    company
    formal_structure
    employees_and_management
    employees_attributes
    snapshots if WITH_SNAPSHOTS
    reoccurrences
    api_client_task_defintions
    jobs_and_convertors
  rescue => e
    ap e.message.red
    puts e.backtrace
    raise e
  end

  def self.company
    puts 'company'
    @c = Company.create!(name: COMPANY_NAME)
    @d = Domain.create!(company_id: @c.id, domain: "#{COMPANY_NAME}.com")
    service = COMPANY_TYPE == 'google' ? 'gmail' : 'domain'
    EmailService.create!(domain_id: @d.id, name: service)
  end

  def self.formal_structure
    puts 'formal structure'
    @root_group = Group.create!(company_id: @c.id, name: COMPANY_NAME)
    @div1 = Group.create!(company_id: @c.id, parent_group_id: @root_group.id, name: 'Division 1', color_id: 1)
    @div2 = Group.create!(company_id: @c.id, parent_group_id: @root_group.id, name: 'Division 2', color_id: 2)
    @dep11 = Group.create!(company_id: @c.id, parent_group_id: @div1.id, name: 'Department1.1', color_id: 3)
    @dep12 = Group.create!(company_id: @c.id, parent_group_id: @div1.id, name: 'Department1.2', color_id: 4)
    @sub_dep111 = Group.create!(company_id: @c.id, parent_group_id: @dep11.id, name: 'SubDepartment1.1.1', color_id: 5)
    @sub_dep112 = Group.create!(company_id: @c.id, parent_group_id: @dep11.id, name: 'SubDepartment1.1.2', color_id: 6)
  end

  def self.employees_and_management
    puts 'emps'
    # top manager
    ceo = Employee.create!(external_id: 1, company_id: @c.id, group_id: @root_group.id, email: "ceo@#{@d[:domain]}", first_name: 'ceo', last_name: 'ceo') unless NO_CEO
    # division managers
    divm1 = create_employee_under_manager(manager: ceo, external_id: 2, company_id: @c.id, group_id: @div1.id, email: "managerd1@#{@d[:domain]}", first_name: 'div1_manager', last_name: 'first') unless NO_MANAGERS
    divm2 = create_employee_under_manager(manager: ceo, external_id: 3, company_id: @c.id, group_id: @div2.id, email: "managerd2@#{@d[:domain]}", first_name: 'div1_manager', last_name: 'second') unless NO_MANAGERS
    # department managers
    depm11 = create_employee_under_manager(manager: divm1, external_id: 4, company_id: @c.id, group_id: @dep11.id, email: "manager11@#{@d[:domain]}", first_name: 'dep1_submanager', last_name: 'first') unless NO_DEP_MANAGERS
    depm12 = create_employee_under_manager(manager: divm1, external_id: 5, company_id: @c.id, group_id: @dep12.id, email: "manager12@#{@d[:domain]}", first_name: 'dep2_submanager', last_name: 'second') unless NO_DEP_MANAGERS

    # sub dep11
    depm111 = create_employee_under_manager(manager: depm11, external_id: 6, company_id: @c.id, group_id: @sub_dep111.id, email: "manager111@#{@d[:domain]}", first_name: 'sub_dep_1_manager', last_name: 'first')
    depm112 = create_employee_under_manager(manager: depm11, external_id: 7, company_id: @c.id, group_id: @sub_dep111.id, email: "manager112@#{@d[:domain]}", first_name: 'sub_dep_2_submanager', last_name: 'second')

    # the rest
    groups_with_managers = [{ group: @div2, manager: divm2 }, { group: @dep11, manager: depm11 }, { group: @dep12, manager: depm12 }, { group: @sub_dep111, manager: depm111 }, { group: @sub_dep112, manager: depm112 }]
    (8..COMPANY_SIZE).each do |n|
      group_with_manager = groups_with_managers.sample
      create_employee_under_manager(manager: group_with_manager[:manager], external_id: n, company_id: @c.id, group_id: group_with_manager[:group].id, email: "google-employee#{n}@#{@d[:domain]}", first_name: 'regular', last_name: "employee#{n}")
    end
  end

  def self.employees_attributes
    puts 'attributes'
    # attributes
    ranks = Rank.pluck(:id)
    age_groups = AgeGroup.pluck(:id)
    seniorities = Seniority.pluck(:id)
    genders = [0, 1]
    Employee.where(company_id: @c.id).each do |emp|
      emp.update(rank_id: ranks.sample, age_group_id: age_groups.sample, seniority_id: seniorities.sample, gender: genders.sample)
      EmployeeAliasEmail.create!(email_alias: "g-emp#{emp.id}@g-company.com", employee_id: emp.id) if rand(0..1) == 1
    end
  end

  def self.snapshots
    puts 'snapshots'
    date = Time.zone.today
    @s = Snapshot.create(company_id: @c.id, timestamp: date, snapshot_type: 1)
    emps = Employee.where(company_id: @c.id)
    friendships = []
    advices = []
    trusts = []
    networks = []
    emps.each do |emp|
      p emp.id
      peers = emps.sample(30)
      emps.each do |other|
        next if other.id == emp.id
        f_flag = rand <= 0.1 ? 1 : 0
        a_flag = rand <= 0.1 ? 1 : 0
        t_flag = rand <= 0.1 ? 1 : 0
        friendships.push  "(#{emp.id}, #{other.id}, #{f_flag}, #{@s.id})"
        advices.push      "(#{emp.id}, #{other.id}, #{a_flag}, #{@s.id})"
        trusts.push       "(#{emp.id}, #{other.id}, #{t_flag}, #{@s.id}, '#{Time.zone.now}', '#{Time.zone.now}')"
        networks.push     "(#{emp.id}, #{other.id}, #{rand(30) + 1}, #{@s.id})" if peers.include? other
      end
    end
    # query_f = "INSERT INTO friendships_snapshots (employee_id, friend_id, friend_flag, snapshot_id) VALUES #{friendships.join(', ')}"
    # query_a = "INSERT INTO advices_snapshots (employee_id, advicee_id, advice_flag, snapshot_id) VALUES #{advices.join(', ')}"
    # query_t = "INSERT INTO trusts_snapshots (employee_id, trusted_id, trust_flag, snapshot_id, created_at, updated_at) VALUES #{trusts.join(', ')}"
    query_n = "INSERT INTO network_snapshot_nodes (employee_from_id, employee_to_id, n1, snapshot_id) VALUES #{networks.join(', ')}"
    # ActiveRecord::Base.connection.execute(query_f)
    # ActiveRecord::Base.connection.execute(query_a)
    # ActiveRecord::Base.connection.execute(query_t)
    ActiveRecord::Base.connection.execute(query_n)
  end

  def self.api_client_task_defintions
    puts 'api_client_task_defintions'
    ######### General tasks #########
    ApiClientTaskDefinition.find_or_create_by(
      name: 'sender',
      script_path: 'sender/sender.rb'
    )
    ApiClientTaskDefinition.find_or_create_by(
      name: 'update_config',
      script_path: './update_config.rb'
    )
    ApiClientTaskDefinition.find_or_create_by(
      name: 'upload_log',
      script_path: './upload_log.rb'
    )

    if COMPANY_TYPE == 'google'
      ApiClientTaskDefinition.find_or_create_by(
        name: 'google monitor creator',
        script_path: 'google/create_monitors.rb'
      )
      ApiClientTaskDefinition.find_or_create_by(
        name: 'google emails collector',
        script_path: 'google/collect_emails.rb'
      )
    end

    if COMPANY_TYPE == 'exchange'
      ApiClientTaskDefinition.find_or_create_by(
        name: 'exchange emails collector',
        script_path: 'exchange/collect_emails_from_date_to_date.rb'
      )
    end
  end

  def self.reoccurrences
    Reoccurrence.create(run_every_by_minutes: 720, fail_after_by_minutes: 720, name: '12_12') unless Reoccurrence.find_by(name: '12_12')
    Reoccurrence.create(run_every_by_minutes: 60, fail_after_by_minutes: 60, name: '1h') unless Reoccurrence.find_by(name: '1h')
    Reoccurrence.create(run_every_by_minutes: 10, fail_after_by_minutes: 10, name: '10m') unless Reoccurrence.find_by(name: '10m')
    Reoccurrence.create(run_every_by_minutes: 10, fail_after_by_minutes: 60, name: '10m_1h') unless Reoccurrence.find_by(name: '10m_1h')
    Reoccurrence.create(run_every_by_minutes: Reoccurrence::MONTH_MINUTES, fail_after_by_minutes: Reoccurrence::MONTH_MINUTES, name: '10m_1h') unless Reoccurrence.find_by(name: 'month')
    Reoccurrence.create(run_every_by_minutes: Reoccurrence::DAY_MINUTES, fail_after_by_minutes: Reoccurrence::DAY_MINUTES, name: '10m_1h') unless Reoccurrence.find_by(name: 'day')
  end

  def self.jobs_and_convertors
    puts 'jobs_and_convertors'
    ######### Google Jobs #########
    collector_job = nil
    if COMPANY_TYPE == 'google'
      j = Job.create!(
        company_id: @c.id,
        next_run: Time.zone.now,
        name: 'test company google monitor creation',
        reoccurrence: Reoccurrence.find_by_name('month'),
        type_number: Job::CLIENT_JOB)
      jtc = JobToApiClientTaskConvertor.create!(
        job_id: j.id,
        algorithm_name: 'test_company_google_create_monitors',
        name: 'test_company_google_create_monitors')
      j.update(job_to_api_client_task_convertor_id: jtc.id)
      # collect_emails

      collector_job = Job.create!(
        company_id: @c.id,
        next_run: Time.zone.now,
        name: 'google test company daily email collection',
        reoccurrence: Reoccurrence.find_by_name('10m_1h'),
        type_number: Job::CLIENT_JOB)
      jtc = JobToApiClientTaskConvertor.create!(
        job_id: collector_job.id,
        algorithm_name: 'daily_emails_collection_from_google_test_company',
        name: 'daily_emails_collection_from_google_test_company')
      collector_job.update(job_to_api_client_task_convertor_id: jtc.id)
    end

    if COMPANY_TYPE == 'exchange'
      collector_job = Job.create!(
        company_id: @c.id,
        next_run: Time.zone.now,
        name: 'exchange test company daily email collection',
        reoccurrence: Reoccurrence.find_by_name('10m_1h'),
        type_number: Job::CLIENT_JOB)
      jtc = JobToApiClientTaskConvertor.create!(
        job_id: collector_job.id,
        algorithm_name: 'daily_emails_collection_from_exchange_test_company',
        name: 'daily_emails_collection_from_exchange_test_company')
      collector_job.update(job_to_api_client_task_convertor_id: jtc.id)
    end

    r = Reoccurrence.find_by_name('10m_1h')
    snapshot_job = Job.create_new_job('db:create_snapshot_for_e2e', nil, r, Job::SYSTEM_JOB, "[#{@c.id},1]")
    snapshot_job.add_as_depeendent_of(collector_job)
    pre_calc_pin_job = Job.create_new_job('db:pre_calculate_pins', nil, r, Job::SYSTEM_JOB, "[#{@c.id}]")
    pre_calc_pin_job.add_as_depeendent_of(snapshot_job)
    pre_calc_metrics_job = Job.create_new_job('db:precalculate_metric_scores', nil, r, Job::SYSTEM_JOB, "[#{@c.id}]")
    pre_calc_metrics_job.add_as_depeendent_of(pre_calc_pin_job)
  end

  private

  def self.create_employee_under_manager(emp_args)
    attrs = emp_args.reject { |k| k == :manager }
    e = Employee.create!(attrs)
    EmployeeManagementRelation.create!(manager_id: emp_args[:manager].id, employee_id: e.id, relation_type: 0) unless emp_args[:manager].nil?
    return e
  end

  run_seed
end
