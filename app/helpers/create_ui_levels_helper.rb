module CreateUiLevelsHelper
  @measure = 1
  @flag = 2
  @gauge = 5
  @higher_gauge = 6
  @wordcloud = 7
  def self.create_ui_level(cid)
    # mock_for_gauge_algorithm_id = CompanyMetric.create!(company_id: nil, algorithm_type_id: @gauge)
    UiLevelConfiguration.where(company_id: cid).delete_all
    @cid = cid
    create_mocked_company_metric_for_each_type
    create_level_1
    create_level_2
    create_level_3
    create_level_4
  end

  def self.create_mocked_company_metric_for_each_type
    @mocked_gauge_company_metric = CompanyMetric.find_or_create_by(id: -1, network_id: -1, company_id: -1, algorithm_type_id: @gauge, algorithm_id: 1)
    @mocked_wordcloud_company_metric = CompanyMetric.find_or_create_by(id: -2, network_id: -1, company_id: -1, algorithm_type_id: 7, algorithm_id: 1)
    @mocked_flag_company_metric = CompanyMetric.find_or_create_by(id: -3, network_id: -1, company_id: -1, algorithm_type_id: @flag, algorithm_id: 1)
    @mocked_measure_company_metric = CompanyMetric.find_or_create_by(id: -4, network_id: -1, company_id: -1, algorithm_type_id: @measure, algorithm_id: 1)
  end

  def self.create_level_1
    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 503).first
    l1_gauge_workflow_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @workflow = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l1_gauge_workflow_cm.gauge_id,
      company_metric_id: l1_gauge_workflow_cm.id,
      name: 'Workflow',
      level: 1,
      display_order: 1,
      color: '#f7973f'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 504).first
    l1_gauge_top_talent_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @top_talent = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l1_gauge_top_talent_cm.gauge_id,
      company_metric_id: l1_gauge_top_talent_cm.id,
      name: 'Top Talent',
      level: 1,
      display_order: 2,
      color: 'rgb(125, 194, 71)'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 502).first
    l1_gauge_productivity_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @productivity = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l1_gauge_productivity_cm.gauge_id,
      company_metric_id: l1_gauge_productivity_cm.id,
      name: 'Productivity',
      level: 1,
      display_order: 3,
      color: 'rgb(234, 31, 122)'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 501).first
    l1_gauge_collaboration_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @collaboration = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l1_gauge_collaboration_cm.gauge_id,
      company_metric_id: l1_gauge_collaboration_cm.id,
      name: 'Collaboration',
      level: 1,
      display_order: 4,
      color: 'rgb(124, 96, 169)'
    )
  end

  def self.create_level_2
    ############## workflow ##############

    @synergy_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 20, maximum_area: 50, background_color: 'rgba(248, 152, 56, 0.16)')
    @influences_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 20, maximum_area: 70, background_color: 'rgba(248, 152, 56, 0.16)')

    # @synergy = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @synergy_gauge_lvl_2.id, name: 'Synergy', level: 2, display_order: 1, parent_id: @workflow.id, color: @workflow.color, description: 'Indicates the level to which workflow and culture are consistent with management plans and goals.  ', observation: 'Word synergy: Based only on email subject and on predetermined words as defined in setup.*Structure synergy: Based on reported lines and roles as provided by company.*Adding either the interactive survey/ email collector increases accuracy.')
    # @influences = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @influences_gauge_lvl_2.id, name: 'Influencers', level: 2, display_order: 2, parent_id: @workflow.id, color: @workflow.color, description: 'Indicates the proportion of facilitators and barriers to workflow within a unit.', observation: 'Adding either the interactive survey/email collector increases accuracy.*When team size is under 15 people, validity drops. Interpret with caution.')
    @empty_tab_1 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @synergy_gauge_lvl_2.id, name: 'Redundancy', level: 2, display_order: 3, parent_id: @workflow.id, color: @workflow.color)
    @empty_tab_2 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @influences_gauge_lvl_2.id, name: 'Structure', level: 2, display_order: 4, parent_id: @workflow.id, color: @workflow.color)

    ############ top talent ###############
    @unrecognized_talent_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 49, background_color: 'rgba(122,201,65, 0.16)')
    @likely_to_leave_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 49, background_color: 'rgba(122,201,65, 0.16)')

    @unrecognized_talent = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @unrecognized_talent_gauge_lvl_2.id, name: 'unrecognized talent', level: 2, display_order: 1, parent_id: @top_talent.id, color: @top_talent.color, description: 'Indicates the proportion of social and professional talents within a unit.', observation: 'Adding either the interactive survey/ email collector increases accuracy.*When team size is under 15 people, validity drops, interpret with caution')
    # @likely_to_leave = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @likely_to_leave_gauge_lvl_2.id, name: 'Likely to leave', level: 2, display_order: 2, parent_id: @top_talent.id, color: @top_talent.color, description: 'Indicates the level of employees at risk of leaving.', observation: 'Prediction is for increased probability of leaving, not actual turnover.*Personal and contextual factors may affect actual turnover.*Adding either the interactive survey/ email collector or receiving more information from HR increases accuracy.')
    @empty_tab_1 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @unrecognized_talent_gauge_lvl_2.id, name: 'Expert power', level: 2, display_order: 3, parent_id: @top_talent.id, color: @top_talent.color)
    @empty_tab_2 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @likely_to_leave_gauge_lvl_2.id, name: 'Key players', level: 2, display_order: 4, parent_id: @top_talent.id, color: @top_talent.color)

    ##### productivity ########

    @time_utilization_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 32, background_color: 'rgba(237,30,121,0.16)')
    @workload_heterogenity_gauge_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 29, maximum_area: 89, background_color: 'rgba(237,30,121,0.16)')

    company_metric                     = CompanyMetric.where(company_id: @cid, algorithm_id: 403).first
    l2_gauge_time_utilization_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @time_utilization = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_time_utilization_cm.gauge_id,
      company_metric_id: l2_gauge_time_utilization_cm.id,
      name: 'Time utilization',
      level: 2,
      display_order: 1,
      parent_id: @productivity.id,
      color: @productivity.color,
      weight: 0.5,
      description: 'Indicates the proportion of time utilized productively within a unit.'
    )

    company_metric                    = CompanyMetric.where(company_id: @cid, algorithm_id: 404).first
    l2_gauge_workload_heterogenity_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @workload_heterogenity = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_workload_heterogenity_cm.gauge_id,
      company_metric_id: l2_gauge_workload_heterogenity_cm.id,
      name: 'Workload Heterogenity',
      level: 2,
      description: 'Describes the level in which workload is distributed within the organization.',
      display_order: 2,
      parent_id: @productivity.id,
      color: @productivity.color,
      weight: 0.5,
      observation: 'Adding the email collector provides improved insights.*Interpret with caution if the unit has undergone personnel changes'
    )

    @empty_tab_1 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @time_utilization_gauge_lvl_2.id, name: 'Resource optimization', level: 2, display_order: 3, parent_id: @productivity.id, color: @productivity.color)
    @empty_tab_2 = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @workload_heterogenity_gauge_lvl_2.id, name: 'Return on investment', level: 2, display_order: 4, parent_id: @productivity.id, color: @productivity.color)

    ##### collaboration ########
    company_metric                     = CompanyMetric.where(company_id: @cid, algorithm_id: 401).first
    l2_gauge_internal_collaboration_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @internal_collaboration = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_internal_collaboration_cm.gauge_id,
      company_metric_id: l2_gauge_internal_collaboration_cm.id,
      name: 'Internal collaboration',
      level: 2,
      display_order: 1,
      parent_id: @collaboration.id,
      color: @collaboration.color,
      weight: 0.5,
      description: 'Describes the level of collaboration with-in the unit',
      observation: 'Adding either the interactive survey/ email collector increases accuracy.*In case the unit size is smaller than 5 people, estimates are less reliable.*In case the unit size is smaller than 15 people, interpret with caution.'
    )

    company_metric                     = CompanyMetric.where(company_id: @cid, algorithm_id: 402).first
    l2_gauge_external_collaboration_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @external_collaboration = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_external_collaboration_cm.gauge_id,
      company_metric_id: l2_gauge_external_collaboration_cm.id,
      name: 'External collaboration',
      level: 2,
      display_order: 2,
      parent_id: @collaboration.id,
      color: @collaboration.color,
      weight: 0.5,
      description: 'Describes the level of collaboration between units',
      observation: 'Adding either the interactive survey/ email collector increases accuracy.*The number of external units may affect the index.*Consider whether the unit is expected to collaborate with others.'
    )
    company_metric          = CompanyMetric.where(company_id: @cid, algorithm_id: 505).first
    @communication_dynamics = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      company_metric_id: company_metric.nil? ? @mocked_measure_company_metric : company_metric.id,
      name: 'Communication dynamics',
      level: 2,
      display_order: 3,
      parent_id: @collaboration.id,
      color: @collaboration.color
    )

    company_metric      = CompanyMetric.where(company_id: @cid, algorithm_id: 405).first
    l2_gauge_synergy_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @synergy = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_synergy_cm.gauge_id,
      company_metric_id: l2_gauge_synergy_cm.id,
      name: 'Synergy',
      level: 2,
      display_order: 1,
      weight: 0.5,
      parent_id: @workflow.id,
      color: @workflow.color,
      description: 'Indicates the level to which workflow and culture are consistent with management plans and goals.  ',
      observation: 'Word synergy: Based only on email subject and on predetermined words as defined in setup.*Structure synergy: Based on reported lines and roles as provided by company.*Adding either the interactive survey/ email collector increases accuracy.'
    )

    company_metric         = CompanyMetric.where(company_id: @cid, algorithm_id: 406).first
    l2_gauge_influences_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @influences = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_influences_cm.gauge_id,
      company_metric_id: l2_gauge_influences_cm.id,
      name: 'Influencers',
      level: 2,
      display_order: 2,
      weight: 0.5,
      parent_id: @workflow.id,
      color: @workflow.color,
      description: 'Indicates the proportion of facilitators and barriers to workflow within a unit.',
      observation: 'Adding either the interactive survey/email collector increases accuracy.*When team size is under 15 people, validity drops. Interpret with caution.'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 407).first
    l2_gauge_likely_to_leave_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @likely_to_leave = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l2_gauge_likely_to_leave_cm.gauge_id,
      company_metric_id: nil,
      # company_metric_id: l2_gauge_likely_to_leave_cm.id,
      name: 'Likely to leave', level: 2, display_order: 2,
      weight: 0.5,
      parent_id: @top_talent.id,
      color: @top_talent.color,
      description: 'Indicates the level of employees at risk of leaving.',
      observation: 'Prediction is for increased probability of leaving, not actual turnover.*Personal and contextual factors may affect actual turnover.*Adding either the interactive survey/ email collector or receiving more information from HR increases accuracy.'
    )
    @empty_tab_1 = UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Blockers', level: 2, display_order: 4, parent_id: @collaboration.id, color: @collaboration.color)
    @empty_tab_2 = UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Facilitators', level: 2, display_order: 5, parent_id: @collaboration.id, color: @collaboration.color)
    @empty_tab_3 = UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Redundency', level: 2, display_order: 6, parent_id: @collaboration.id, color: @collaboration.color)
  end

  def self.create_level_3
    ############## workflow ##############

    # @keyword_alignment_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 20, maximum_area: 30, background_color: 'rgba(248, 152, 56, 0.16)')
    @structure_alignment_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 30, maximum_area: 91, background_color: 'rgba(248, 152, 56, 0.16)')
    @proportion_influences_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 20, maximum_area: 70, background_color: 'rgba(248, 152, 56, 0.16)')
    @proportion_barriers_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 30, maximum_area: 60, background_color: 'rgba(248, 152, 56, 0.16)')
    # @keyword_alignment = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @keyword_alignment_gauge_lvl_3.id, name: 'Keyword Alignment', level: 3, display_order: 1, parent_id: @synergy.id, color: @synergy.color)

    @keyword_alignment = UiLevelConfiguration.find_or_create_by(company_metric_id: -1, company_id: @cid, gauge_id: -1, name: 'Keyword Alignment', level: 3, display_order: 1, parent_id: @synergy.id, color: @synergy.color)
    # @structure_alignment = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @structure_alignment_gauge_lvl_3.id, name: 'Structure alignment', level: 3, display_order: 2, parent_id: @synergy.id, color: @synergy.color)


    company_metric                      = CompanyMetric.where(company_id: @cid, algorithm_id: 314).first
    l3_gauge_proportion_influencers_cm  = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @proportion_influences = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_proportion_influencers_cm.gauge_id,
      company_metric_id: l3_gauge_proportion_influencers_cm.id,
      name: 'Proportion influencers',
      level: 3,
      display_order: 3,
      parent_id: @influences.id,
      color: @influences.color,
      weight: 0.5,
      description: 'Indicates facilitators for workflow'
    )

    # @proportion_barriers = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @proportion_barriers_gauge_lvl_3.id, name: 'Proportion Barriers', level: 3, display_order: 4, parent_id: @influences.id, color: @influences.color, description: 'Indicates barriers for workflow')
    ############ top talent ###############

    @social_talent_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 49, background_color: 'rgba(122,201,65, 0.16)')
    @professional_talent_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 30, maximum_area: 91, background_color: 'rgba(122,201,65, 0.16)')
    @overworked_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 49, background_color: 'rgba(122,201,65, 0.16)')
    @at_risk_gauge_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 15, maximum_area: 70, background_color: 'rgba(122,201,65, 0.16)')

    @social_talent = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @social_talent_gauge_lvl_3.id, name: 'Social talent', level: 3, display_order: 1, parent_id: @unrecognized_talent.id, color: @unrecognized_talent.color, description: 'Indicates employees who are important socially')
    @professional_talent = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @professional_talent_gauge_lvl_3.id, name: 'Professional talent', level: 3, display_order: 2, parent_id: @unrecognized_talent.id, color: @unrecognized_talent.color)
    # @overworked = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @overworked_gauge_lvl_3.id, name: 'Overworked', level: 3, display_order: 1, parent_id: @likely_to_leave.id, color: @likely_to_leave.color)
    @at_risk = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @at_risk_gauge_lvl_3.id, name: 'At risk', level: 3, display_order: 2, parent_id: @likely_to_leave.id, color: @likely_to_leave.color)

    ##### productivity ########

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 306).first
    l3_gauge_email_specifity = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @email_specifity = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_email_specifity.gauge_id,
      company_metric_id: l3_gauge_email_specifity.id,
      name: 'Email specificity',
      level: 3,
      display_order: 2,
      parent_id: @time_utilization.id,
      color: @time_utilization.color,
      weight: 0.33,
      description: 'Indicates whether emails are sent only to the appropriate recipients'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 305).first
    l3_gauge_time_spent_on_emails = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @time_spent_on_emails = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_time_spent_on_emails.gauge_id,
      company_metric_id: l3_gauge_time_spent_on_emails.id,
      name: 'Time spent on emails',
      level: 3,
      display_order: 1,
      parent_id: @time_utilization.id,
      color: @time_utilization.color,
      weight: 0.33,
      description: 'Indicates the time spent on emails'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 307).first
    l3_gauge_time_spent_on_meetings = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @time_spent_on_meetings = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_time_spent_on_meetings.gauge_id,
      company_metric_id: l3_gauge_time_spent_on_meetings.id,
      name: 'Time spent on meetings',
      level: 3,
      display_order: 3,
      parent_id: @time_utilization.id,
      color: @time_utilization.color,
      weight: 0.33,
      description: 'Indicates how much time is spent on meetings'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 309).first
    l3_gauge_hidden_unemployment = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @hidden_unemployment = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_hidden_unemployment.gauge_id,
      company_metric_id: l3_gauge_hidden_unemployment.id,
      name: 'Hidden unemployment',
      level: 3,
      display_order: 1,
      parent_id: @workload_heterogenity.id,
      color: @workload_heterogenity.color,
      weight: 0.5,
      description: 'Indicates hidden unemployment'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 310).first
    l3_gauge_hidden_overemployment = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @hidden_overemployment = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_hidden_overemployment.gauge_id,
      company_metric_id: l3_gauge_hidden_overemployment.id,
      name: 'Hidden overemployment',
      level: 3,
      display_order: 2,
      parent_id: @workload_heterogenity.id,
      color: @workload_heterogenity.color,
      weight: 0.5,
      description: 'Indicates overworked employees'
    )

    ##### collaboration ########

    company_metric                 = CompanyMetric.where(company_id: @cid, algorithm_id: 301).first
    l3_gauge_knowledge_sharing_cm  = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @knowledge_sharing = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_knowledge_sharing_cm.gauge_id,
      company_metric_id: l3_gauge_knowledge_sharing_cm.id,
      name: 'Knowledge sharing',
      level: 3,
      display_order: 1,
      parent_id: @internal_collaboration.id,
      color: @internal_collaboration.color,
      weight: 0.33,
      description: 'Indicates the extent to which knowledge is shared within groups'
    )

    company_metric            = CompanyMetric.where(company_id: @cid, algorithm_id: 302).first
    l3_gauge_team_cohesion_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @team_cohesion = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_team_cohesion_cm.gauge_id,
      company_metric_id: l3_gauge_team_cohesion_cm.id,
      name: 'Team cohesion',
      level: 3,
      display_order: 2,
      parent_id: @internal_collaboration.id,
      color: @internal_collaboration.color,
      weight: 0.33,
      description: 'Indicates the extent to which the team is united'
    )

    company_metric                  = CompanyMetric.where(company_id: @cid, algorithm_id: 303).first
    l3_gauge_collaboration_risks_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @collaboration_risks = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_collaboration_risks_cm.gauge_id,
      company_metric_id: l3_gauge_collaboration_risks_cm.id,
      name: 'Collaboration risks',
      level: 3,
      display_order: 3,
      parent_id: @internal_collaboration.id,
      color: @internal_collaboration.color,
      weight: 0.33,
      description: 'Indicates potential fault lines that may harm team cohesiveness'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 304).first
    l3_gauge_external_knowladge_collaboration_cm = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @external_knowledge_sharing = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_external_knowladge_collaboration_cm.gauge_id,
      company_metric_id: l3_gauge_external_knowladge_collaboration_cm.id,
      name: 'Knowledge sharing',
      level: 3,
      display_order: 1,
      parent_id: @external_collaboration.id,
      color: @external_collaboration.color,
      weight: 1.0,
      description: 'Indicates the extent to which knowledge is shared between groups'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 311).first
    l3_gauge_structure_alignment = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @structure_alignment = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_structure_alignment.gauge_id,
      company_metric_id: l3_gauge_structure_alignment.id,
      name: 'Structure alignment',
      level: 3,
      display_order: 2,
      parent_id: @synergy.id,
      color: @synergy.color,
      weight: 0.33
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 312).first
    l3_gauge_proportion_barriers = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @proportion_barriers = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_proportion_barriers.gauge_id,
      company_metric_id: l3_gauge_proportion_barriers.id,
      name: 'Proportion Barriers',
      level: 3,
      display_order: 4,
      parent_id: @influences.id,
      color: @influences.color,
      weight: 0.5,
      description: 'Indicates barriers for workflow'
    )

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 313).first
    l3_gauge_overworked = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    @overworked = UiLevelConfiguration.find_or_create_by(
      company_id: @cid,
      gauge_id: l3_gauge_overworked.gauge_id,
      company_metric_id: l3_gauge_overworked.id,
      name: 'Overworked',
      level: 3,
      display_order: 1,
      parent_id: @likely_to_leave.id,
      color: @likely_to_leave.color,
      weight: 1
    )
  end

  def self.create_level_4
    most_bypassed_manger_id = 74
    most_social_power_id = 62
    expert_id = 63
    central_id = 65
    seek_advice_id = 71
    political_power_id = 154

    most_bypassed_manger = CompanyMetric.where(company_id: @cid, algorithm_id: most_bypassed_manger_id, algorithm_type_id: @flag).first
    most_bypassed_manger = @mocked_flag_company_metric if most_bypassed_manger.nil?
    expert = CompanyMetric.where(company_id: @cid, algorithm_id: expert_id, algorithm_type_id: @measure).first
    central = CompanyMetric.where(company_id: @cid, algorithm_id: central_id, algorithm_type_id: @measure).first
    most_social_power = CompanyMetric.where(company_id: @cid, algorithm_id: most_social_power_id, algorithm_type_id: @measure).first
    seek_advice = CompanyMetric.where(company_id: @cid, algorithm_id: seek_advice_id, algorithm_type_id: @measure).first
    # CompanyMetric.where(company_id: @cid, algorithm_id: most_bypassed_manger, algorithm_type_id: @flag)
    algo_isolate_information_id = Algorithm.find_by(id: 100, name: 'calculate_information_isolate_to_args', algorithm_type_id: 2, algorithm_flow_id: 1).try(:id)
    algo_pwerful_non_managers = Algorithm.find_by(id: 101, name: 'calculate_powerful_non_managers_to_args', algorithm_type_id: 2, algorithm_flow_id: 1).try(:id)
    algo_bottlenecks_id = Algorithm.find_by(id: 130, name: 'calculate_bottlenecks_for_flag', algorithm_type_id: 2, algorithm_flow_id: 1).try(:id)

    information_isolate_company_metric_id  = CompanyMetric.where(company_id: @cid, algorithm_id: algo_isolate_information_id).first
    information_isolate_company_metric_id  = @mocked_flag_company_metric if information_isolate_company_metric_id.nil?
    powerful_non_manager_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: algo_pwerful_non_managers).first
    powerful_non_manager_company_metric_id = @mocked_flag_company_metric if powerful_non_manager_company_metric_id.nil?
    political_power_company_metric_id      = CompanyMetric.where(company_id: @cid, algorithm_id: political_power_id).first
    political_power_company_metric_id      = @mocked_flag_company_metric if powerful_non_manager_company_metric_id.nil?

    sink_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: 141).first
    sink_company_metric_id = @mocked_flag_company_metric if sink_company_metric_id.nil?

    information_bottleneck_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: algo_bottlenecks_id).first
    information_bottleneck_metric_id = @mocked_flag_company_metric if information_bottleneck_metric_id.nil?

    # gatekeepers_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: algo_gatekeepers_information_id).first
    ############## workflow ##############
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Wordcloud', level: 4, display_order: 1, parent_id: @keyword_alignment.id, company_metric_id: @mocked_wordcloud_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Keyword heterogeneity', level: 4, display_order: 2, parent_id: @keyword_alignment.id, company_metric_id: @mocked_gauge_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Wordreach', level: 4, display_order: 3, parent_id: @keyword_alignment.id, company_metric_id: @mocked_gauge_company_metric.id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Bypassed managers', level: 4, display_order: 1, parent_id: @structure_alignment.id, description: 'Indicates formal managers that are relatively "out of the loop"', weight: 0.33, company_metric_id: most_bypassed_manger.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Information isolates', weight: 0.33, level: 4, display_order: 2, parent_id: @structure_alignment.id, description: 'Indicates employees who receive and send relatively little information', company_metric_id: information_isolate_company_metric_id.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Powerfull nonmanager', level: 4, display_order: 3, parent_id: @structure_alignment.id, description: 'Indicates employees who do not have a formal management roles ,yet are central within the network', weight: 0.33, company_metric_id: powerful_non_manager_company_metric_id.try(:id))

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Political power', level: 4, display_order: 1, parent_id: @proportion_influences.id, weight: 0.2, description: 'Indicates employees who receive a high proportion of implicit communication', company_metric_id: political_power_company_metric_id.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Information power centers', level: 4, display_order: 2, parent_id: @proportion_influences.id, weight: 0.2, description: 'Indicates areas within the units with high information transactions', company_metric_id: expert.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Change agents', level: 4, display_order: 3, parent_id: @proportion_influences.id, weight: 0.2, description: 'Indicates employees who are important to engage for succesful organizational changes due to their high connectivity between and within units', company_metric_id: @mocked_gauge_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Decision makers', level: 4, display_order: 4, parent_id: @proportion_influences.id, weight: 0.2, description: 'Indicates employees who are key to decision making processes', company_metric_id: central.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Social power', level: 4, display_order: 5, parent_id: @proportion_influences.id, weight: 0.2, description: 'Indicates employees who are friends with other powerful employees', company_metric_id: most_social_power.try(:id))

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Advice seekers', level: 4, display_order: 1, parent_id: @proportion_barriers.id, company_metric_id: seek_advice.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Bottlenecks', level: 4, display_order: 2, parent_id: @proportion_barriers.id, weight: 0.5, description: 'Indicates employees who are critical in information flow, without whom information flow would be greatly reduced', company_metric_id: information_bottleneck_metric_id.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Sinks', level: 4, display_order: 3, parent_id: @proportion_barriers.id, weight: 0.5, description: 'Indicates employees who rarely reply to messages sent to them', company_metric_id: sink_company_metric_id.id)

   ###### top talent ########

    at_risk_id = 72
    CompanyMetric.where(company_id: @cid, algorithm_id: at_risk_id, algorithm_type_id: @flag).first
    expert_id = 63
    expert = CompanyMetric.where(company_id: @cid, algorithm_id: expert_id, algorithm_type_id: @measure).first

    popular_id = 61
    popular = CompanyMetric.where(company_id: @cid, algorithm_id: popular_id, algorithm_type_id: @measure).first

    team_glue_id = 66
    team_glue = CompanyMetric.where(company_id: @cid, algorithm_id: team_glue_id, algorithm_type_id: @measure).first

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 124).first
    email_proportion = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 126).first
    bottleneck_gauge = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 125).first
    representatives = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 133).first
    gate_keepers_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 137).first
    volume_of_emails = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 139).first
    no_isolates = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 143).first
    no_of_emails_sent = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 145).first
    no_of_emails_received = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 149).first
    avg_of_emails_subject = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Change agents', level: 4, display_order: 1, parent_id: @social_talent.id, description: 'Indicates employees with high friendship and/or trust relations that are important to engage for successful organizational changes', company_metric_id: @mocked_flag_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Social power', level: 4, display_order: 2, parent_id: @social_talent.id, description: 'Indicates the emplyees that are trusted and/or friends with a lot of employees, and are connected to other employees that have relativly a lot of friendship/trust connections', company_metric_id: popular.try(:id))
    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 147).first
    no_of_sinks = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Change agents', level: 4, display_order: 1, parent_id: @social_talent.id, description:'Indicates employees with high friendship and/or trust relations that are important to engage for successful organizational changes', company_metric_id: @mocked_flag_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Social power', level: 4, display_order: 2, parent_id: @social_talent.id,description:'Indicates the emplyees that are trusted and/or friends with a lot of employees, and are connected to other employees that have relativly a lot of friendship/trust connections', company_metric_id: popular.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Team glue', level: 4, display_order: 3, parent_id: @social_talent.id, company_metric_id: team_glue.try(:id))

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Experts', level: 4, display_order: 1, parent_id: @professional_talent.id, company_metric_id: expert.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Proportion of non-managerial experts', level: 4, display_order: 3, parent_id: @professional_talent.id, description: 'Indicates emplyees who do not have a formal managment role, yet employees seek their advice', company_metric_id: @mocked_flag_company_metric.id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Bottlenecks', level: 4, display_order: 1, weight: 0.33, parent_id: @overworked.id, description: 'Proportion of employees who are overworked because they are on a critical information path', company_metric_id: @mocked_flag_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Representative', level: 4, display_order: 2, weight: 0.33, parent_id: @overworked.id, description: 'Indicates employees who are critical in information flow and send relativly alot of emails outside group', company_metric_id: representatives.id)
    # UiLevelConfiguration.find_or_create_by(company_id: @cid, name:'likely to leave', level: 4, display_order: 3, parent_id: @overworked.id, company_metric_id: at_risk_id.try(:id))
    # UiLevelConfiguration.find_or_create_by(company_id: @cid, name:'Gate Keepers', level: 4, display_order: 3, parent_id: @overworked.id, description: '', company_metric_id: gatekeepers_metric_id.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Gatekeepers', weight: 0.33, level: 4, display_order: 3, parent_id: @overworked.id, description: 'Indicates employees who are critical to information flow to the group', company_metric_id: gate_keepers_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Delayed promotion', level: 4, display_order: 1, parent_id: @at_risk.id, company_metric_id: @mocked_flag_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Toxic neighborhoods', level: 4, display_order: 2, parent_id: @at_risk.id, description: 'emplyees whose friends and/or trustees have quit, and hence are more likely to leave as well', company_metric_id: @mocked_gauge_company_metric.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Proportion of experts who would benefit from more formal communication', level: 4, display_order: 3, parent_id: @at_risk.id, company_metric_id: @mocked_flag_company_metric.id)

    ##### productivity ########

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 157).first
    average_no_of_attendees = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 158).first
    proportion_time_spent_on_meetings = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 159).first
    proportion_of_managers_never_in_meetings = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'No of emails sent', level: 4, display_order: 1, parent_id: @time_spent_on_emails.id, description: 'No. of emails sent in the organization', weight: 0.25, company_metric_id: no_of_emails_sent.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'No of emails received', weight: 0.25, level: 4, display_order: 2, parent_id: @time_spent_on_emails.id, description: 'No. of emails sent in the organization', company_metric_id: no_of_emails_received.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Average subject length', level: 4, display_order: 3, parent_id: @time_spent_on_emails.id, weight: 0.25, description: 'Average number of words within subject tab', company_metric_id: avg_of_emails_subject.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Volume of emails', level: 4, display_order: 5, parent_id: @time_spent_on_emails.id, description: 'average of volume of emails sent and received per group in the organization', company_metric_id: volume_of_emails.id, weight:0.25)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Average mailing list size', level: 4, display_order: 1, parent_id: @email_specifity.id, description: 'Average number of recipients in organizations mailing lists', company_metric_id: @mocked_gauge_company_metric.id, weight: 0.5)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Proportion of mails in mailing list', level: 4, display_order: 2, parent_id: @email_specifity.id, weight: 0.5, description: 'Proportion number of emails sent in mailing lists out of all emails sent', company_metric_id: email_proportion.id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Proportion time spent on meetings', level: 4, display_order: 1, weight: 0.5, parent_id: @time_spent_on_meetings.id, description: 'Proportion of time spent on meetings overall working time', company_metric_id: proportion_time_spent_on_meetings.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Average number of attendees', level: 4, display_order: 2, weight: 0.5, parent_id: @time_spent_on_meetings.id, company_metric_id: average_no_of_attendees.id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'No of isolates', level: 4, display_order: 1, parent_id: @hidden_unemployment.id, description: 'Proportion of employees who recieve very few emails', company_metric_id: no_isolates.id, weight: 0.33)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'No of sinks', level: 4, display_order: 2, parent_id: @hidden_unemployment.id, description: 'Proportion of employees who do not reply to emails sent to them', company_metric_id: no_of_sinks.id, weight: 0.33)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Proportion managers never in meetings', level: 4, display_order: 4, parent_id: @hidden_unemployment.id, description: 'Proportion of formal managers who are not invited to meetings', company_metric_id: proportion_of_managers_never_in_meetings.id, weight: 0.33)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'No of bottlenecks', level: 4, display_order: 1, parent_id: @hidden_overemployment.id, company_metric_id: bottleneck_gauge.id, weight: 0.5)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Mailing list overload', level: 4, display_order: 2, parent_id: @hidden_overemployment.id, description: 'Indicates the proportion of employees who are overloaded because they receive many mails through mailing lists', company_metric_id: @mocked_gauge_company_metric.id, weight: 0.5)

    ##### collaboration ########
    central = 64
    trusting = 67
    socially_activity = 70
    representatives = 129
    non_reciprocity_information_id = Algorithm.find_by(id: 102, name: 'calculate_non_reciprocity_between_employees_to_args', algorithm_type_id: 2, algorithm_flow_id: 1).try(:id)
    non_reciprocity_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: non_reciprocity_information_id).first
    representatives_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: representatives, algorithm_type_id: @flag).first.try(:id)
    center_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: central, algorithm_type_id: @measure).first.try(:id)
    trusting_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: trusting, algorithm_type_id: @measure).first.try(:id)
    socially_company_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: socially_activity, algorithm_type_id: @measure).first.try(:id)
    representatives_company_metric_id = @mocked_flag_company_metric.id if representatives_company_metric_id.nil?

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 103).first
    trust_friendship_centrality_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 104).first
    advice_email_centrality_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 105).first
    gender_faultline_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 106).first
    role_faultline_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 107).first
    office_faultline_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 108).first
    advice_email_density_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 109).first
    trust_friendship_density_gauge_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 110).first
    external_fault_lines_id = company_metric.nil? ? @mocked_gauge_company_metric : company_metric
    company_metric = CompanyMetric.where(company_id: @cid, algorithm_id: 120).first
    embed_email_network = company_metric.nil? ? @mocked_gauge_company_metric : company_metric

    algo_gatekeepers_information_id = Algorithm.find_by(id: 135, name: 'calculate_gate_keepers_for_flag', algorithm_type_id: 2, algorithm_flow_id: 1).try(:id)
    gatekeepers_metric_id = CompanyMetric.where(company_id: @cid, algorithm_id: algo_gatekeepers_information_id).first


    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Knowledge sharing volume', weight: 0.5, level: 4, display_order: 1, parent_id: @knowledge_sharing.id, description: 'Indicates the proportion of emails/advice relations in a group from all possible relations', company_metric_id: advice_email_density_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Knowledge sharing concentration', weight: 0.5, level: 4, display_order: 2, parent_id: @knowledge_sharing.id, description: 'Indicates the extent to which emails/advice/knowledge sharing in a group is centered on a few key employees', company_metric_id: advice_email_centrality_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Collaboration', level: 4, display_order: 3, parent_id: @knowledge_sharing.id, company_metric_id: center_company_metric_id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Team social climate', weight: 0.5, level: 4, display_order: 1, parent_id: @team_cohesion.id, description: 'Indicates the proportion of social relations in a group from all possible relations', company_metric_id: trust_friendship_density_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Social concentration', weight: 0.5, level: 4, display_order: 2, parent_id: @team_cohesion.id, description: 'Indicates the extent to which social relations in a group are centered on a few key employees', company_metric_id: trust_friendship_centrality_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Trusting', level: 4, display_order: 3, parent_id: @team_cohesion.id, company_metric_id: trusting_company_metric_id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Socially active', level: 4, display_order: 4, parent_id: @team_cohesion.id, company_metric_id: socially_company_metric_id)
    # UiLevelConfiguration.find_or_create_by(company_id: @cid, name:'Embeddeness of emails in other networks', level: 4, display_order: 5, parent_id: @team_cohesion.id, company_metric_id:embed_email_network.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Embeddeness of emails in other networks', level: 4, display_order: 5, parent_id: @team_cohesion.id, company_metric_id: embed_email_network.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Nonreciprocity', level: 4, display_order: 1, parent_id: @collaboration_risks.id, description: 'Indicates employees with regards to how much they are not tied', company_metric_id: non_reciprocity_company_metric_id.try(:id))

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Ei index (Faultlines) - Gender', weight: 0.33, level: 4, display_order: 2, parent_id: @collaboration_risks.id, description: 'Indicates the extent to which the group is divided due to employee characteristics (gender, seniority etc)', company_metric_id: gender_faultline_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Ei index (Faultlines) - Role', weight: 0.33, level: 4, display_order: 3, parent_id: @collaboration_risks.id, description: 'Indicates the extent to which the group is divided due to employee characteristics (gender, seniority etc)', company_metric_id: role_faultline_gauge_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Ei index (Faultlines) - Office', weight: 0.33, level: 4, display_order: 4, parent_id: @collaboration_risks.id, description: 'Indicates the extent to which the group is divided due to employee characteristics (gender, seniority etc)', company_metric_id: office_faultline_gauge_id.id)

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Ei index (External)', weight: 0.33, level: 4, display_order: 1, parent_id: @external_knowledge_sharing.id, company_metric_id: external_fault_lines_id.id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Gate Keepers', level: 4, display_order: 2, parent_id: @external_knowledge_sharing.id, description: 'Indicates employees who are critical to information flow to the group', company_metric_id: gatekeepers_metric_id.try(:id))

    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Representatives', weight: 0.33, level: 4, display_order: 3, parent_id: @external_knowledge_sharing.id, description: 'Indicates employees who are critical to information flow from the group', company_metric_id: representatives_company_metric_id)
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'New collaboration', weight: 0.33, level: 4, display_order: 4, parent_id: @external_knowledge_sharing.id, description: 'Indicates new collaboration between employees', company_metric_id: 1411)
  end
end
