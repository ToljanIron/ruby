# frozen_string_literal: true
module UiLevelConfigurationHelper
  COLLABORATION_COLOR = 'rgb(234, 31, 122)'

  def build_ui_level_tree(cid)
    tree_head = {}
    children = []
    sort_tabs(UiLevelConfiguration.where(level: 1, company_id: cid).all).each do |level|
      children.push(all_children_for_node(level.id, level.color)) unless level.nil?
    end
    tree_head[:children] = children
    return tree_head
  end

  def sort_tabs(array_of_tabs)
    result = []
    correct_order = ['Workflow', 'Top Talent', 'Productivity', 'Collaboration']
    correct_order.each do |name|
      result.push array_of_tabs.where(name: name).first
    end
    return result
  end

  def all_children_for_node(ui_level, parent_color)
    res = {}
    children_arr = []
    ui_level_id = ui_level.class == Fixnum ? ui_level : ui_level.id
    current_ui_level = UiLevelConfiguration.find(ui_level_id)
    children = UiLevelConfiguration.where(parent_id: current_ui_level.id)
    children.each do |child|
      children_arr.push(all_children_for_node(child, parent_color))
    end
    current_gauge = current_ui_level.gauge
    unless current_gauge.nil?
      gauge_config = { min_range: current_gauge.minimum_value, max_range: current_gauge.maximum_value, min_range_wanted: current_gauge.minimum_area, max_range_wanted: current_gauge.maximum_area, rate: 60, radius: 120, title: '', background_color: current_gauge.background_color }
    end
    current_ui_level_company_metric = CompanyMetric.where(id: current_ui_level.company_metric_id).first
    res[:color] = current_ui_level.color.nil? ? parent_color : current_ui_level.color
    res[:observation] = current_ui_level.observation
    res[:description] = current_ui_level.description
    res[:id] = current_ui_level.id
    res[:level] = current_ui_level.level
    res[:parent_id] = current_ui_level.parent_id
    res[:display_order] = current_ui_level.display_order
    res[:name] = current_ui_level.name
    res[:company_metric_id] = current_ui_level_company_metric.try(:id)
    res[:algorithm_type] = current_ui_level_company_metric.try(:algorithm_type_id)
    res[:gauge] = gauge_config
    res[:children] = children_arr

    return res
  end

  def generate_l4s_for_questionnaire_only(cid)
    sqlstr =
      "select cm.id, cm.network_id, cm.algorithm_id, nn.name as network_name
       from company_metrics as cm
       join algorithms as algo on algo.id = cm.algorithm_id
       join network_names as nn on nn.id = cm.network_id
       where
       cm.company_id = #{cid} and
       algo.algorithm_type_id = 8
       order by network_name, algorithm_id"
    measures = ActiveRecord::Base.connection.select_all(sqlstr).to_hash
    l4s = []
    i = 1
    measures.each do |m|
      cmid = m['id'].to_i
      l4s << {
        id:   CompanyMetric.generate_ui_level_id_for_questionnaire_only(m['id']),
        name: CompanyMetric.generate_metric_name_for_questionnaire_only(m['network_name'], m['algorithm_id']),
        algorithm_type: 1,
        company_metric_id: cmid,
        color: COLLABORATION_COLOR,
        description: nil,
        display_order: i,
        level: 4,
        observation: nil,
        parent_id: 6,
        children: []
      }
      i += 1
    end
    l4s
  end

  def build_ui_level_3_for_questionnaire_only(l4s_arr)
    return {
      id: 6,
      name: 'L3',
      algorithm_type: 6,
      company_metric_id: 1030,
      color: COLLABORATION_COLOR,
      description: nil,
      display_order: 1,
      level: 3,
      observation: nil,
      parent_id: 5,
      gauge: dummy_gauge_details,
      children: l4s_arr
    }
  end

  def build_ui_level_2_for_questionnaire_only(l3)
    return {
      id: 5,
      name: 'L2',
      algorithm_type: 6,
      company_metric_id: 1030,
      color: COLLABORATION_COLOR,
      description: nil,
      display_order: 1,
      level: 2,
      observation: nil,
      parent_id: 4,
      gauge: dummy_gauge_details,
      children: [l3]
    }
  end

  def build_ui_level_questionnaire_only(cid)
    l4s_arr = generate_l4s_for_questionnaire_only(cid)
    l3 = build_ui_level_3_for_questionnaire_only(l4s_arr)
    l2 = build_ui_level_2_for_questionnaire_only(l3)

    res = []
    res << { id: 1, name: 'Workflow', algorithm_type: 6, company_metric_id: 1022, color: '#f7973f', description: nil, display_order: 1, level: 1, observation: nil, parent_id: nil, gauge: dummy_gauge_details, children: [] }
    res << { id: 2, name: 'Top Talent', algorithm_type: 6, company_metric_id: 1023, color: 'rgb(125, 194, 71)', description: nil, display_order: 2, level: 1, observation: nil, parent_id: nil, gauge: dummy_gauge_details, children: [] }
    res << { id: 3, name: 'Productivity', algorithm_type: 6, company_metric_id: 1021, color: 'rgb(234, 31, 122)', description: nil, display_order: 3, level: 1, observation: nil, parent_id: nil, gauge: dummy_gauge_details, children: [] }
    res << { id: 4, name: 'Collaboration', algorithm_type: 6, company_metric_id: 1020, color: 'rgb(124, 96, 169)', description: nil, display_order: 4, level: 1, observation: nil, parent_id: nil, gauge: dummy_gauge_details, children: [l2]}
    return {children: res}
  end

  def dummy_gauge_details
    return {
      background_color: '#111111',
      max_range: 1,
      max_range_wanted: 0.5,
      min_range: -1,
      min_range_wanted: -0.5,
      radius: 120,
      rate: 0,
      title: ''
    }
  end
end
