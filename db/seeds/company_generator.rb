module CompanyGeneratorSeed

  COMPANY_SIZE = 5
  COMPANY_NAME = 'Acme'
  COMPANY_DOMAIN = 'acme.com'
  COMPANY_TYPE = 'exchange'
  NO_CEO = false
  NO_MANAGERS = false
  NO_DEP_MANAGERS = false

  def self.run_seed
    if ENV['DELETE_COMP']
      puts "In delete mode"

      #cid = Company.find_by(name: COMPANY_NAME).id
      #sid = Snapshot.find_by(company_id: cid).id

      #Group.where(company_id: cid).delete_all
      #CdsMetricScore.where(company_id: cid).delete_all
      #NetworkSnapshotData.where(snapshot_id: sid).delete_all
      #EmailSnapshotData.where(snapshot_id: sid).delete_all
      #NetworkName.where(company_id: cid).delete_all
      #CompanyMetric.where(company_id: cid).delete_all
      #MetricName.where(company_id: cid).delete_all
      #GaugeConfiguration.where(company_id: cid).delete_all
      #Employee.where(company_id: cid).delete_all
      #Snapshot.find(sid).delete
      #Company.find(cid).delete

      ActiveRecord::Base.connection.execute('TRUNCATE companies RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE snapshots RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE employees RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE gauge_configurations RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE metric_names RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE company_metrics RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE network_names RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE email_snapshot_data RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE network_snapshot_data RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE cds_metric_scores RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE groups RESTART IDENTITY')
      ActiveRecord::Base.connection.execute('TRUNCATE employee_management_relations RESTART IDENTITY')

      puts "Done"

    else

      puts "In create mode"

      company
      formal_structure
      employees_and_management
      employees_attributes
      networks
      snapshots

      CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_trust_friendship_centrality(@c.id)

      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_powerful_non_managers(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_non_reciprocity(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_trust_friendship_centrality(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_email_advice_centrality(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_email_advice_density(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_internal_faultlines(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_network_density(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_external_fault(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_new_seed_for_proportion_emails(@c.id)
      #CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper.create_company_metrics_for_analyze_superposition_graph(@c.id)

      cid = Company.find_by(name: COMPANY_NAME).id
      sid = Snapshot.find_by(company_id: cid).id
      gid = Group.find_by(name: COMPANY_NAME).id
      puts "Company ID: #{cid}"
      puts "Snapshot ID: #{sid}"
      puts "Group ID: #{gid}"
    end

  rescue => e
    ap e.message[0..1000].red
    puts e.backtrace
    raise e
  end

  def self.company
    puts 'company'
    @c = Company.where(id: 2,name: COMPANY_NAME).first_or_create(name: COMPANY_NAME)
    @d = Domain.where(domain: COMPANY_DOMAIN).first_or_create(company_id: @c.id, domain: COMPANY_DOMAIN)
    service = COMPANY_TYPE == 'google' ? 'gmail' : 'domain'
    EmailService.where(name: service).first_or_create(domain_id: @d.id, name: service)
  end

  def self.formal_structure
    puts 'formal structure'
    @root_group = Group.create!(company_id: @c.id, name: COMPANY_NAME)
    @div1       = Group.create!(company_id: @c.id, parent_group_id: @root_group.id, name: 'Division 1')
    @div2       = Group.create!(company_id: @c.id, parent_group_id: @root_group.id, name: 'Division 2')
    @dep11      = Group.create!(company_id: @c.id, parent_group_id: @div1.id, name: 'Department1.1')
    @dep12      = Group.create!(company_id: @c.id, parent_group_id: @div1.id, name: 'Department1.2')
    @sub_dep111 = Group.create!(company_id: @c.id, parent_group_id: @dep11.id, name: 'SubDepartment1.1.1')
    @sub_dep112 = Group.create!(company_id: @c.id, parent_group_id: @dep11.id, name: 'SubDepartment1.1.2')
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
      puts "Employee number: #{n}" if (n % 100) == 0
      create_employee_under_manager(manager: group_with_manager[:manager], external_id: n, company_id: @c.id, group_id: group_with_manager[:group].id, email: "employee#{n}@#{@d[:domain]}", first_name: 'regular', last_name: "employee#{n}")
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

  def self.networks
    puts "Netowrks"
    @anid = NetworkName.find_or_create_by!(name: 'Advice',     company_id: @c.id).id
    @fnid = NetworkName.find_or_create_by!(name: 'Friendship', company_id: @c.id).id
    @tnid = NetworkName.find_or_create_by!(name: 'Trust',      company_id: @c.id).id
  end

  def self.snapshots
    puts 'snapshots'
    date = Time.zone.today
    @s = Snapshot.create(company_id: @c.id, timestamp: date, snapshot_type: 1)
    emps = Employee.where(company_id: @c.id).order(:email)
    networks = []
    emails = []
    num = 0

    emps.each do |emp|
      puts "Working on employee: #{emp.email}" if (num % 10 ==0)
      peers = emps.sample(30)

      nids = [@anid, @fnid, @tnid]

      emps.each do |other|
        next if other.id == emp.id
        num += 1
        nid = nids[rand(3)]
        networks.push  "(#{@s.id}, #{nid}, #{@c.id}, #{emp.id}, #{other.id}, 1, #{@s.id})" if rand < 0.5
        emails.push    "(#{emp.id}, #{other.id}, #{rand(30) + 1}, #{@s.id})" if peers.include? other

        if num == 50000
          query_n = "INSERT INTO network_snapshot_data (snapshot_id, network_id, company_id, from_employee_id, to_employee_id, value, original_snapshot_id) VALUES #{networks.join(', ')}"
          query_e = "INSERT INTO email_snapshot_data (employee_from_id, employee_to_id, n1, snapshot_id) VALUES #{emails.join(', ')}"
          ActiveRecord::Base.connection.execute(query_n)
          ActiveRecord::Base.connection.execute(query_e)

          num      = 0
          networks = []
          emails   = []

          puts "Num of emails: #{EmailSnapshotData.count}"
          puts "Num of network relations: #{NetworkSnapshotData.count}"
        end
      end
    end

    if !networks.empty?
      query_n = "INSERT INTO network_snapshot_data (snapshot_id, network_id, company_id, from_employee_id, to_employee_id, value, original_snapshot_id) VALUES #{networks.join(', ')}"
      ActiveRecord::Base.connection.execute(query_n)
    end

    if !emails.empty?
      query_e = "INSERT INTO email_snapshot_data (employee_from_id, employee_to_id, n1, snapshot_id) VALUES #{emails.join(', ')}"
      ActiveRecord::Base.connection.execute(query_e)
    end

    puts "Num of emails: #{EmailSnapshotData.count}"
    puts "Num of network relations: #{NetworkSnapshotData.count}"

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
