# Creates a network for each employee in company,
# based on his groups, managers and previous behaviour of his coworkers in questionnaires
# number of coworkers in a network is
# CompanyConfigurationTable.find_by(key: 'max_questionnaire_population', comp_id: cid)[:value] or DEFAULT_MAX_QUESTIONNAIRE_POPULATION,
# but maximum is reached only when it's smaller than company size
# otherwise company size is a maximum

module PopulateQuestionnaireHelper
  # scores
  FRIEND_OF_FRIEND ||= 1
  PICKED_ME ||= 100
  UNDER_SAME_MANAGER ||= 3
  UNDER_ME ||= 3
  PEER_RECEIVER ||= 3
  IN_MY_GROUP ||= 3
  IN_SIBLING_GROUPS ||= 1
  IN_PARENT_GROUP ||= 2
  IN_DAUGHTER_GROUPS ||= 2
  MANAGER ||= 3
  RANDOM ||= 1

  DEFAULT_MAX_QUESTIONNAIRE_POPULATION ||= 100

  def self.run(cid)
    employees = Employee.by_company(cid)
    company_maximum = CompanyConfigurationTable.find_by(key: 'max_questionnaire_population', comp_id: cid).try(:value).try(:to_i) || DEFAULT_MAX_QUESTIONNAIRE_POPULATION
    puts "Building #{company_maximum} connections per employee"
    company_connections = {}
    i = 0
    employees.each do |emp|
      connections = friends_of_friends(emp) if answered_before?(emp)
      connections = [:who_picked_me, :under_same_manager, :under_me, :my_peer_receivers, :in_my_group, :in_sibling_groups, :in_parent_group, :in_daughter_groups, :manager]
                    .inject(connections || {}) do |a, e|
                      sum_hashes(a, send(e, emp))
                    end
                    .select { |k, _| k != emp.id }
      connections = if connections.size < company_maximum
                      sum_hashes(connections, random_emps(emp, connections, company_maximum))
                    else
                      connections.sort_by { |_, score| -score }[0..(company_maximum - 1)]
                    end.map { |pr| pr[0].to_i }
      company_connections[emp.id.to_s] = connections
      i += connections.length
      if i % 900 == 0
        puts "Completed #{i} connections"
        write(company_connections)
        company_connections = {}
      end
    end
    write(company_connections)
  end

  def self.write(connections)
    # write to db
    ActiveRecord::Base.transaction do
      begin
        EmployeesConnection.where(employee_id: connections.keys.map(&:to_i)).delete_all
        values = []
        connections.each do |emp_id, conns|
          conns.each { |con_id| values << "(#{emp_id}, #{con_id})" }
        end
        ActiveRecord::Base.connection.execute("INSERT INTO employees_connections (employee_id, connection_id) VALUES #{values.join(',')}")
      rescue => e
        puts e.message
        puts e.backtrace.join("\n") unless ENV['RAILS_ENV'] == 'test'
        raise ActiveRecord::Rollback
      end
    end
  end

  def self.random_emps(emp, connections, company_maximum)
    length = company_maximum - connections.size
    sid = Snapshot.last_snapshot_of_company(emp[:company_id])
    emp_array = Employee.where(snapshot_id: sid)
                        .where.not(id: [emp.id] + connections.keys)
                        .pluck(:id)
                        .sample(length)
    res = emp_array.map { |id| [id, RANDOM] }.to_h
    puts "Randomly picked for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.manager(emp)
    return EmployeeManagementRelation
      .where(employee_id: emp.id, relation_type: [0,1])
      .pluck(:manager_id)
      .map { |id| [id, MANAGER] }.to_h
  end

  def self.in_daughter_groups(emp)
    daughter_groups = Group.where(parent_group_id: emp[:group_id])
    res = PopulateQuestionnaireHelper.employees_in_groups(daughter_groups.pluck(:id), emp, IN_DAUGHTER_GROUPS)
    puts "Emps in daughter groups for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.in_parent_group(emp)
    group = Group.find_by(id: emp[:group_id])
    return [] if group.nil?
    parent_group_id = group[:parent_group_id]
    res = PopulateQuestionnaireHelper.employees_in_groups(parent_group_id, emp, IN_PARENT_GROUP)
    puts "Emps in parent group for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.in_sibling_groups(emp)
    group = Group.find_by(id: emp[:group_id])
    return [] if group.nil?
    sibling_groups = group.sibling_groups
    res = PopulateQuestionnaireHelper.employees_in_groups(sibling_groups.pluck(:id), emp, IN_SIBLING_GROUPS)
    puts "Emps in sibling groups for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.in_my_group(emp)
    res = PopulateQuestionnaireHelper.employees_in_groups(emp[:group_id], emp, IN_MY_GROUP)
    puts "Emps in own group for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.my_peer_receivers(emp) # count only significant peers
    last_snapshot = Company.find(emp[:company_id]).last_snapshot
    company_id = Company.find(emp[:company_id]).id
    network = NetworkSnapshotData.emails(company_id)
    emp_array = NetworkSnapshotData.select("to_employee_id, count(id) as sm")
                                   .where(network_id: network, snapshot_id: last_snapshot.id, from_employee_id: emp.id)
                                   .group(:to_employee_id)
    emp_array = emp_array.map {|e| {to_employee_id: e.to_employee_id, sum: e.sm}}
    emp_array = emp_array.sort {|a,b| b[:sum] <=> a[:sum] }
    res = {}
    res =            emp_array[0..4].map   { |e| [e[:to_employee_id], PEER_RECEIVER * 3] }.to_h
    res = res.merge( emp_array[5..15].map  { |e| [e[:to_employee_id], PEER_RECEIVER * 2] }.to_h ) if !emp_array[5..15].nil?
    res = res.merge( emp_array[16..-1].map { |e| [e[:to_employee_id], PEER_RECEIVER]     }.to_h )     if !emp_array[16..-1].nil?
    puts "Emps who are email peers for emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.under_me(emp)
    emp_array = EmployeeManagementRelation.where(manager_id: emp.id).pluck(:employee_id)
    res = emp_array.map { |id| [id, UNDER_ME] }.to_h
    puts "Emps managed by emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.under_same_manager(emp)
    return {} if EmployeeManagementRelation.where(employee_id: emp.id).empty?
    managers_ids = EmployeeManagementRelation.where(employee_id: emp.id, relation_type: [0,1]).pluck(:manager_id)
    emp_array = EmployeeManagementRelation
                .where(manager_id: managers_ids, relation_type: [0,1])
                .where.not(employee_id: emp.id)
                .pluck(:employee_id)
    res = emp_array.map { |id| [id, UNDER_SAME_MANAGER] }.to_h
    puts "Emps managed under same manager as emp ID: #{emp.id}" if false
    ap res if false
    return res
  end

  def self.who_picked_me(emp)
    last_questionnaire = Questionnaire.where(company_id: emp[:company_id]).last
    return {} if last_questionnaire.nil? || last_questionnaire.completed?
    emp_participants = QuestionnaireParticipant.where(employee_id: emp.id, questionnaire_id: last_questionnaire.id).pluck(:id)
    qp_who_picked_emp = last_questionnaire
                        .questionnaire_questions
                        .inject([]) do |a, e|
                          a + e
                              .question_replies # get all replies
                              .where(reffered_questionnaire_participant_id: emp_participants, answer: true) # select all `true` replies about emp
                              .pluck(:questionnaire_participant_id)
                        end
    emps = QuestionnaireParticipant.where(id: qp_who_picked_emp).pluck(:employee_id).uniq
    emp_array = emps.map { |eid| [eid, PICKED_ME] }
    res = emp_array.to_h
    puts "Emps who mpicked emp ID: #{emp.id} in last questionnaire" if false
    ap res if false
    return res
  end

  def self.friends_of_friends(emp) # TODO: rewrite logic after first questionnaire is completed
    previous_friends_of_friends = previous_friends(emp)
                                  .inject([]) { |a, e| a + previous_friends(Employee.find(e)) }
                                  .uniq
                                  .delete_if { |id| id == emp.id }
                                  .map do |eid|
                                    [eid, FRIEND_OF_FRIEND] # TODO: if the dude is on the list more than once he should get higher score probably? - then remove .uniq
                                  end
    res = previous_friends_of_friends.to_h
    puts "Emps managed under same manager as emp ID: #{emp.id}" if false
    return res
  end

  def self.employees_in_groups(groups_ids, emp, value)
    return Employee.where(group_id: groups_ids)
                   .where.not(id: emp.id)
                   .map { |e| [e.id, value] }.to_h
  end

  def self.previous_friends(emp)
    return [] if emp.nil? || Questionnaire.where(company_id: emp[:company_id]).empty?
    friendship = NetworkName.find_by(company_id: emp[:company_id], name: 'Friendship')
    emp_participants = QuestionnaireParticipant.where(employee_id: emp.id, status: 'completed')
    previous_qs_ids = emp_participants.pluck(:questionnaire_id)
    friend_qs = Questionnaire.where(id: previous_qs_ids).inject([]) do |a, e|
      a + e.questionnaire_questions.where(network_id: friendship.id).pluck(:id) # completed questions on friendship
    end
    questionnaire_participants = QuestionReply
                                 .where(questionnaire_question_id: friend_qs, questionnaire_participant_id: emp_participants.pluck(:id), answer: true)
                                 .pluck(:reffered_questionnaire_participant_id).uniq
    QuestionnaireParticipant.where(id: questionnaire_participants).pluck(:employee_id)
  end

  def self.answered_before?(emp)
    return false if Questionnaire.where(company_id: emp[:company_id]).empty?
    return QuestionnaireParticipant.where(employee_id: emp.id).any?(&:completed?)
  end

  def self.sum_hashes(h1, h2)
    result = {}
    h1.each { |k, v| result[k] = h2[k] ? v + h2[k] : v }
    h2.each { |k, v| result[k] = v if result[k].nil? }
    result
  end
end
