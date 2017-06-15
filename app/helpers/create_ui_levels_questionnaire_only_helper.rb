module CreateUiLevelsQuestionnaireOnlyHelper
  @measure = 1
  @flag = 2
  @gauge = 5
  @higher_gauge = 6
  @wordcloud = 7
  def self.create_ui_level_questionnaire_only(cid)
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
    @mocked_gauge_company_metric_lvl_2 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 0, maximum_area: 49, background_color: 'rgba(122,201,65, 0.16)')
    @mocked_gauge_company_metric = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @mocked_gauge_company_metric_lvl_2.id, name: 'unrecognized talent', level: 2, display_order: 1, parent_id: @collaboration.id)
  end

  def self.create_level_3
    @mocked_gauge_company_metric_lvl_3 = GaugeConfiguration.find_or_create_by(minimum_value: 0, maximum_value: 100, minimum_area: 30, maximum_area: 91, background_color: 'rgba(122,201,65, 0.16)')
    @mocked_gauge_company_metric = UiLevelConfiguration.find_or_create_by(company_id: @cid, gauge_id: @mocked_gauge_company_metric_lvl_3.id, name: 'Professional talent', level: 3, display_order: 2, parent_id: @mocked_gauge_company_metric.id)
  end

  def self.create_level_4
    expert_id = 63
    seek_advice_id = 71
    seek_advice = CompanyMetric.where(company_id: @cid, algorithm_id: seek_advice_id, algorithm_type_id: @measure).first
    expert = CompanyMetric.where(company_id: @cid, algorithm_id: expert_id, algorithm_type_id: @measure).first
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Experts', level: 4, display_order: 1, parent_id: @mocked_gauge_company_metric.id, company_metric_id: expert.try(:id))
    UiLevelConfiguration.find_or_create_by(company_id: @cid, name: 'Advice seekers', level: 4, display_order: 2, parent_id: @mocked_gauge_company_metric.id, company_metric_id: seek_advice.try(:id))
  end
end
