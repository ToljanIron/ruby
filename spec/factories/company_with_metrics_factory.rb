module CompanyWithMetricsFactory
  def create_company_data
    create_metrics
    create_company
    create_groups
    create_employees
    create_friendships_and_advices
    create_email_snapshot_data
    create_snapshots
  end

  @nemp = 100
  @nsnapshots = 12
  @emp_emails = (1..@nemp).map { |i| "emp#{i}@example.com" }

  def create_metrics
    FactoryBot.create(:metric, name: 'Collaboration', metric_type: 'measure', index: 1)
    FactoryBot.create(:metric, name: 'Most Isolated', metric_type: 'measure', index: 2)
    FactoryBot.create(:metric, name: 'Most Social', metric_type: 'measure', index: 3)
    FactoryBot.create(:metric, name: 'Most Expert', metric_type: 'measure', index: 4)
    FactoryBot.create(:metric, name: 'Centrality', metric_type: 'measure', index: 5)
    FactoryBot.create(:metric, name: 'Central', metric_type: 'measure', index: 6)
    FactoryBot.create(:metric, name: 'Most Trusted', metric_type: 'measure', index: 7)
    FactoryBot.create(:metric, name: 'Most Trusting', metric_type: 'measure', index: 8)
    FactoryBot.create(:metric, name: 'In the Loop', metric_type: 'measure', index: 9)
    FactoryBot.create(:metric, name: 'Political Centrality', metric_type: 'measure', index: 10)
    FactoryBot.create(:metric, name: 'At Risk of Leaving', metric_type: 'flag', index: 0)
    FactoryBot.create(:metric, name: 'Most Promissing Talent', metric_type: 'flag', index: 1)
    FactoryBot.create(:metric, name: 'Most Bypassed Manager', metric_type: 'flag', index: 2)
    FactoryBot.create(:metric, name: 'Team Glue', metric_type: 'flag', index: 3)
    FactoryBot.create(:metric, name: 'Collaboration', metric_type: 'analyze', index: 0)
    FactoryBot.create(:metric, name: 'Friendship', metric_type: 'analyze', index: 1)
    FactoryBot.create(:metric, name: 'Social Power', metric_type: 'analyze', index: 2)
    FactoryBot.create(:metric, name: 'Expert', metric_type: 'analyze', index: 3)
    FactoryBot.create(:metric, name: 'Trust', metric_type: 'analyze', index: 4)
    FactoryBot.create(:metric, name: 'Centrality', metric_type: 'analyze', index: 5)
    FactoryBot.create(:metric, name: 'Central', metric_type: 'analyze', index: 6)
    FactoryBot.create(:metric, name: 'In the Loop', metric_type: 'analyze', index: 7)
    FactoryBot.create(:metric, name: 'Political Centrality', metric_type: 'analyze', index: 8)
  end

  def create_algorithms_and_algorithm_type
    AlgorithmType.create(id: 1, name: 'measure')
    AlgorithmType.create(id: 2, name: 'flag')
    AlgorithmType.create(id: 3, name: 'analyze')
    AlgorithmType.create(id: 4, name: 'group_measure')

    FactoryBot.create(:algorithm_flow, id: 1, name: 'questionair')
    FactoryBot.create(:algorithm_flow, id: 2, name: 'email')
    FactoryBot.create(:algorithm, id: 3,  name: 'get_most_social_to_args', algorithm_type_id: 1, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 31, name: 'get_most_social_to_args', algorithm_type_id: 3, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 4,  name: 'get_friends_relation_in_network_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 27, name: 'most_isolated_to_args', algorithm_type_id: 1, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 25, name: 'get_advice_out_network_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 7,  name: 'find_most_expert_to_args', algorithm_type_id: 1, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 32, name: 'find_most_expert_to_args', algorithm_type_id: 3, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 8,  name: 'at_risk_of_leaving_to_args', algorithm_type_id: 2)
    FactoryBot.create(:algorithm, id: 9,  name: 'most_promising_worker_to_args', algorithm_type_id: 2, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 10, name: 'most_bypassed_manager_to_args', algorithm_type_id: 2, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 11, name: 'team_glue_to_args', algorithm_type_id: 2, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 12, name: 'get_trust_in_network_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 33, name: 'get_trust_in_network_to_args', algorithm_type_id: 3, algorithm_flow_id: 2)
    FactoryBot.create(:algorithm, id: 13, name: 'get_trust_out_network_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 14, name: 'centrality_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 30, name: 'centrality_to_args', algorithm_type_id: 3, algorithm_flow_id: 2)
    FactoryBot.create(:algorithm, id: 15, name: 'central_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 34, name: 'central_to_args', algorithm_type_id: 3, algorithm_flow_id: 2)
    FactoryBot.create(:algorithm, id: 18, name: 'total_activity_centrality_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 19, name: 'delegator_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 20, name: 'knowledge_distributor_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 22, name: 'most_isolated_group_active_to_args', algorithm_type_id: 4)
    FactoryBot.create(:algorithm, id: 23, name: 'most_aloof_group_active_to_args', algorithm_type_id: 4)
    FactoryBot.create(:algorithm, id: 24, name: 'most_self_sufficient_group_to_args', algorithm_type_id: 4)
    FactoryBot.create(:algorithm, id: 26, name: 'get_friends_out_network_to_args', algorithm_type_id: 1)
    FactoryBot.create(:algorithm, id: 28, name: 'collaboration', algorithm_type_id: 1, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 29, name: 'collaboration', algorithm_type_id: 3, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 21, name: 'politically_active_to_args')
    FactoryBot.create(:algorithm, id: 17, name: 'politician_to_args', algorithm_type_id: 3)
    FactoryBot.create(:algorithm, id: 16, name: 'in_the_loop_to_args', algorithm_type_id: 1, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 35, name: 'in_the_loop_to_args', algorithm_type_id: 3, algorithm_flow_id: 1)
    FactoryBot.create(:algorithm, id: 104, name: 'advice_email_centrality', algorithm_type_id: 5, algorithm_flow_id: 1)
  end

  def create_company_metrics_company_0
    FactoryBot.create(:company_metric, id: 203, metric_id: 1, network_id: 1, company_id: 0, algorithm_id: 3, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 204, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 4, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 205, metric_id: 1, network_id: 3, company_id: 0, algorithm_id: 5, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 206, metric_id: 1, network_id: 3, company_id: 0, algorithm_id: 7, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 207, metric_id: 1, network_id: 3, company_id: 0, algorithm_id: 6, algorithm_params: '{"in_or_out":"in"}', algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 208, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 14, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 209, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 15, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 210, metric_id: 1, network_id: 4, company_id: 0, algorithm_id: 12, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 211, metric_id: 1, network_id: 4, company_id: 0, algorithm_id: 13, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 212, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 19, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 213, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 18, algorithm_type_id: 1)

    FactoryBot.create(:company_metric, id: 215, metric_id: 9, network_id: 1, company_id: 0, algorithm_id: 9, algorithm_type_id: 2, algorithm_params: '{"network_b_id": 3}')
    FactoryBot.create(:company_metric, id: 216, metric_id: 10, network_id: 1, algorithm_params: '{"network_b_id": 3}', company_id: 0, algorithm_id: 8, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 217, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 11, algorithm_type_id: 2)

    FactoryBot.create(:company_metric, id: 219, metric_id: 15, network_id: 2, company_id: 0, algorithm_id: 22, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 220, metric_id: 1, network_id: 2, company_id: 0, algorithm_id: 23, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 221, metric_id: 12, network_id: 2, company_id: 0, algorithm_id: 24, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 224, metric_id: 24, network_id: 2, company_id: 0, algorithm_id: 26, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 225, metric_id: 24, network_id: 2, company_id: 0, algorithm_id: 10, algorithm_params: '{"network_b_id": 3}', algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 229, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 20, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 230, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 27, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 232, metric_id: 20, network_id: 3, company_id: 0, algorithm_id: 25, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 233, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 28, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 234, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 29, algorithm_type_id: 3)

    FactoryBot.create(:company_metric, id: 235, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 16, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 236, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 17, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 237, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 21, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 240, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 30, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 241, metric_id: 20, network_id: 1, company_id: 0, algorithm_id: 31, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 242, metric_id: 20, network_id: 3, company_id: 0, algorithm_id: 32, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 243, metric_id: 20, network_id: 4, company_id: 0, algorithm_id: 33, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 244, metric_id: 20, network_id: 2, company_id: 0, algorithm_id: 34, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 245, metric_id: 20, network_id: 2, company_id: 0, algorithm_id: 35, algorithm_type_id: 3)


  end

  def create_company_metrics_company_1
    FactoryBot.create(:company_metric, id: 1, metric_id: 1, network_id: 1, company_id: 1, algorithm_id: 1, algorithm_type_id: 1)

    FactoryBot.create(:company_metric, id: 238, metric_id: 20, network_id: 1, company_id: 1, algorithm_id: 17, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 2, metric_id: 1, network_id: 1, company_id: 1, algorithm_id: 2, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 3, metric_id: 1, network_id: 1, company_id: 1, algorithm_id: 3, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 31, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 4, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 5, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 5, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 6, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 7, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 7, metric_id: 1, network_id: 3, company_id: 1, algorithm_id: 6, algorithm_params: '{"in_or_out":"in"}', algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 8, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 14, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 9, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 15, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 10, metric_id: 1, network_id: 4, company_id: 1, algorithm_id: 12, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 11, metric_id: 1, network_id: 4, company_id: 1, algorithm_id: 13, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 12, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 19, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 13, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 18, algorithm_type_id: 1)

    FactoryBot.create(:company_metric, id: 15, metric_id: 9, network_id: 2, company_id: 1, algorithm_id: 9, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 16, metric_id: 10, network_id: 3, algorithm_params: '{"network_b_id": 1, "network_a_id": 3}', company_id: 1, algorithm_id: 8, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 17, metric_id: 20, network_id: 1, company_id: 1, algorithm_id: 11, algorithm_type_id: 2)

    FactoryBot.create(:company_metric, id: 19, metric_id: 15, network_id: 2, company_id: 1, algorithm_id: 22, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 20, metric_id: 1, network_id: 2, company_id: 1, algorithm_id: 23, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 21, metric_id: 12, network_id: 2, company_id: 1, algorithm_id: 24, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 24, metric_id: 24, network_id: 24, company_id: 1, algorithm_id: 26, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 25, metric_id: 24, network_id: 24, company_id: 1, algorithm_id: 10, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 29, metric_id: 20, network_id: 1, company_id: 1, algorithm_id: 20, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 30, metric_id: 20, network_id: 1, company_id: 1, algorithm_id: 27, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 32, metric_id: 20, network_id: 1, company_id: 1, algorithm_id: 25, algorithm_type_id: 2)
  end

  def create_company_metrics_company_2
    FactoryBot.create(:company_metric, id: 101, metric_id: 1, network_id: 1, company_id: 2, algorithm_id: 1, algorithm_type_id: 1)

    FactoryBot.create(:company_metric, id: 102, metric_id: 1, network_id: 1, company_id: 2, algorithm_id: 2, algorithm_type_id: 3)
    FactoryBot.create(:company_metric, id: 103, metric_id: 1, network_id: 1, company_id: 2, algorithm_id: 3, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 1031, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 4, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 105, metric_id: 1, network_id: 3, company_id: 2, algorithm_id: 5, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 106, metric_id: 1, network_id: 3, company_id: 2, algorithm_id: 7, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 107, metric_id: 1, network_id: 3, company_id: 2, algorithm_id: 6, algorithm_params: '{"in_or_out":"in"}', algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 108, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 14, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 109, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 15, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 110, metric_id: 1, network_id: 4, company_id: 2, algorithm_id: 12, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 111, metric_id: 1, network_id: 4, company_id: 2, algorithm_id: 13, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 112, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 19, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 113, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 18, algorithm_type_id: 1)

    FactoryBot.create(:company_metric, id: 115, metric_id: 9, network_id: 2, company_id: 2, algorithm_id: 9, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 116, metric_id: 10, network_id: 3, algorithm_params: '{"network_b_id": 1, "network_a_id": 3}', company_id: 2, algorithm_id: 8, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 117, metric_id: 20, network_id: 1, company_id: 2, algorithm_id: 11, algorithm_type_id: 2)

    FactoryBot.create(:company_metric, id: 119, metric_id: 15, network_id: 2, company_id: 2, algorithm_id: 22, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 120, metric_id: 1, network_id: 2, company_id: 2, algorithm_id: 23, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 121, metric_id: 12, network_id: 2, company_id: 2, algorithm_id: 24, algorithm_type_id: 4)
    FactoryBot.create(:company_metric, id: 124, metric_id: 24, network_id: 24, company_id: 2, algorithm_id: 26, algorithm_type_id: 1)
    FactoryBot.create(:company_metric, id: 125, metric_id: 24, network_id: 24, company_id: 2, algorithm_id: 10, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 129, metric_id: 20, network_id: 1, company_id: 2, algorithm_id: 20, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 130, metric_id: 20, network_id: 1, company_id: 2, algorithm_id: 27, algorithm_type_id: 2)
    FactoryBot.create(:company_metric, id: 132, metric_id: 20, network_id: 1, company_id: 2, algorithm_id: 25, algorithm_type_id: 2)
  end

  def create_network_names
    FactoryBot.create(:network_name, id: 1, name: 'Friendship', company_id: 1)
    FactoryBot.create(:network_name, id: 2, name: 'Communication Flow', company_id: 1)
    FactoryBot.create(:network_name, id: 3, name: 'Advice', company_id: 1)
    FactoryBot.create(:network_name, id: 4, name: 'Trust', company_id: 1)
  end

  def create_metric_names
    FactoryBot.create(:metric_name, id: 1, name: 'Popular', company_id: 1)
    FactoryBot.create(:metric_name, id: 2, name: 'Most Isolated', company_id: 1)
    FactoryBot.create(:metric_name, id: 3, name: 'Most Social', company_id: 1)  #friend
    FactoryBot.create(:metric_name, id: 4, name: 'Most Expert', company_id: 1)
    FactoryBot.create(:metric_name, id: 5, name: 'Centrality', company_id: 1)
    FactoryBot.create(:metric_name, id: 6, name: 'Central', company_id: 1)
    FactoryBot.create(:metric_name, id: 7, name: 'Most Trusted', company_id: 1)
    FactoryBot.create(:metric_name, id: 15, name: 'Most Isolate', company_id: 1)
    FactoryBot.create(:metric_name, id: 10, name: 'At Risk of Leaving', company_id: 1)
    FactoryBot.create(:metric_name, id: 11, name: 'Most Promissing Talent', company_id: 1)
    FactoryBot.create(:metric_name, id: 12, name: 'Most Bypassed Manager', company_id: 1)
    FactoryBot.create(:metric_name, id: 13, name: 'Team Glue', company_id: 1)
    FactoryBot.create(:metric_name, id: 14, name: 'Social Power', company_id: 1)
    FactoryBot.create(:metric_name, id: 16, name: 'Expert', company_id: 1)
    FactoryBot.create(:metric_name, id: 17, name: 'Trust', company_id: 1)
    FactoryBot.create(:metric_name, id: 20, name: 'centrality', company_id: 1)
    FactoryBot.create(:metric_name, id: 21, name: 'Most Isolated Group', company_id: 0)
    FactoryBot.create(:metric_name, id: 22, name: 'Most Aloof Group', company_id: 0)
    FactoryBot.create(:metric_name, id: 23, name: 'Trust', company_id: 0)
    FactoryBot.create(:metric_name, id: 24, name: 'centrality', company_id: 0)
  end

  def create_company
    Company.create(id: 1, name: 'Comp1')
  end

  def create_employees
    @employees = (1..@nemp).map do |i|
      FactoryBot.create(:group_employee, id: i, email: @emp_emails[i - 1], group_id: 1)
    end
  end

  def create_groups
    Group.create(id: 1, name: 'group1', company_id: 1)
  end

  def create_friendships_and_advices
    @employees.each do |emp|
      @employees.each do |other|
        next if other.id == emp.id
        f_flag = rand <= 0.1 ? 1 : 0
        a_flag = rand <= 0.1 ? 1 : 0
        FactoryBot.create(:friendship, employee_id: emp, friend_id: other, friend_flag: f_flag)
        FactoryBot.create(:advice, employee_id: emp.id, advicee_id: other.id, advice_flag: a_flag)
      end
    end
  end

  def create_email_snapshot_data
    (1..@nsnapshots).each do |n|
      @employees.each do |emp|
        @employees.sample(rand 10).each do |other|
          next if emp.id == other.id
          (0..rand(6)).each do
            FactoryBot.create(:network_snapshot_node, employee_from_id: emp.id, employee_to_id: other.id, snapshot_id: n)
          end
        end
      end
    end
  end

  def create_snapshots
    (1..@nsnapshots).each do |n|
      sn = Snapshot.create(name: "Monthly-2014-#{n}", snapshot_type: 1, company_id: 1)
      sn.update(timestamp: sn[:created_at])
      @employees.each do |emp|
        @employees.each do |other|
          next if other.id == emp.id
          f_flag = rand <= 0.1 ? 1 : 0
          a_flag = rand <= 0.1 ? 1 : 0
          FactoryBot.create(:friendships_snapshot, employee_id: emp.id, friend_id: other.id, friend_flag: f_flag, snapshot_id: n)
          FactoryBot.create(:advices_snapshot, employee_id: emp.id, advicee_id: other.id, advice_flag: a_flag, snapshot_id: n)
        end
      end
    end
  end
end
