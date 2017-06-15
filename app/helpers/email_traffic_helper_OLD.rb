module EmailTrafficHelper
  include AdviseHelper
  EMAIL_IN   ||= 'to_employee_id'
  EMAIL_OUT  ||= 'from_employee_id'
  TO_MATRIX  ||= 1
  CC_MATRIX  ||= 2
  BCC_MATRIX ||= 3
  ALL_MATRIX ||= 4

  ####################### API ##########################################################
  def centrality(snapshot_id, group_id, pin_id)
    res = calc_normalized_indegree_for_all_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def central(snapshot_id, group_id, pin_id)
    res = calc_normalized_indegree_for_to_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def politically_active(snapshot_id, group_id, pin_id)
    res = calc_normalized_outdegree_for_bcc_matrix(snapshot_id, group_id, pin_id)
    return res.sort_by { |item| item[:measure] }.reverse if res != -1
    return []
  end

  def calc_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAIL_IN, group_id, pin_id)
  end

  def calc_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_degree_for_all_matrix(snapshot_id, EMAIL_OUT, group_id, pin_id)
  end

  def calc_max_outdegree_for_all_matrix(snapshot_id, group_id, pin_id)
    result_vector = calc_outdegree_for_all_matrix(snapshot_id, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_indegree_for_all_matrix(snapshot_id, group_id, pin_id)
    result_vector = calc_indegree_for_all_matrix(snapshot_id, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_avgout_degree_for_all_matrix(snapshot_id)
    result_vector = calc_outdegree_for_all_matrix(snapshot_id, -1, -1)
    comp1 = find_company_by_snapshot(snapshot_id)
    company_size = get_unit_size(comp1, -1, -1)
    total_sum = result_vector.inject(0) { |memo, emp| memo += emp[:measure] }
    return -1 if company_size == 0
    (total_sum.to_f / company_size).round(2)
  end

  def calc_normalized_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAIL_OUT, group_id, pin_id)
  end

  def calc_indegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_indeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
  end

  def calc_indegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_indeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
  end

  def calc_indegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
  end

  def calc_outdegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
  end

  def calc_avgout_degree_for_to_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX)
  end

  def calc_avgout_degree_for_cc_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX)
  end

  def calc_avgout_degree_for_bcc_matrix(snapshot_id)
    calc_avg_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX)
  end

  def calc_avgin_degree_for_to_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, TO_MATRIX)
  end

  def calc_avgin_degree_for_cc_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, CC_MATRIX)
  end

  def calc_avgin_degree_for_bcc_matrix(snapshot_id)
    calc_avg_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX)
  end

  def calc_normalized_indegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_all_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_all_matrix(snapshot_id, EMAIL_OUT, group_id, pin_id)
  end

  def calc_normalized_indegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, TO_MATRIX, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_indegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, CC_MATRIX, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_indegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, BCC_MATRIX, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_to_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, TO_MATRIX, EMAIL_OUT, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_cc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, CC_MATRIX, EMAIL_OUT, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_bcc_matrix(snapshot_id, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, BCC_MATRIX, EMAIL_OUT, group_id, pin_id)
  end

  ############################ ALL MATRIX IMPLEMENTATION #########################################

  def calc_degree_for_all_matrix(snapshot_id, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = []
    emp_list = []
    if direction == EMAIL_IN
      to_degree = calc_indeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
      cc_degree = calc_indeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
      bcc_degree = calc_indeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
    else
      to_degree = calc_outdeg_for_specified_matrix(snapshot_id, TO_MATRIX, group_id, pin_id)
      cc_degree = calc_outdeg_for_specified_matrix(snapshot_id, CC_MATRIX, group_id, pin_id)
      bcc_degree = calc_outdeg_for_specified_matrix(snapshot_id, BCC_MATRIX, group_id, pin_id)
    end
    union = to_degree + cc_degree + bcc_degree
    union.each do |entry|
      res[entry[:id]] = 0  if res[entry[:id]].nil?
      res[entry[:id]] += entry[:measure]
    end
    res.each_with_index { |entry, index| emp_list << { id: index, measure: entry } unless entry.nil? }
    emp_list
  end

  def calc_normalized_degree_for_all_matrix(snapshot_id, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = (direction == EMAIL_IN) ? calc_indegree_for_all_matrix(snapshot_id, group_id, pin_id) : calc_outdegree_for_all_matrix(snapshot_id, group_id, pin_id)
    maximum = (direction == EMAIL_IN) ? calc_max_indegree_for_all_matrix(snapshot_id, -1, -1) : calc_max_outdegree_for_all_matrix(snapshot_id, -1, -1)
    return res if maximum == 0
    return -1 if maximum.nil?
    res.map { |emp| { id: emp[:id], measure: (emp[:measure] /= maximum.to_f).round(2) } }
  end

  def calc_indeg_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix(snapshot_id, matrix_name, EMAIL_IN, group_id, pin_id)
  end

  def calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    return calc_degree_for_specified_matrix(snapshot_id, matrix_name, EMAIL_OUT, group_id, pin_id)
  end

  def calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, direction, group_id = NO_GROUP, pin_id = NO_PIN)
    res = calc_degree_for_specified_matrix(snapshot_id, matrix_name, direction, group_id, pin_id)
    maximum = calc_max_degree_for_specified_matrix(snapshot_id, matrix_name, direction)
    return res if maximum == 0
    return -1 if maximum.nil?
    # return -1 if maximum.nil?     ASAF BYEBUG this is the original
    res.map { |emp| { id: emp[:id], measure: (emp[:measure] /= maximum.to_f).round(2) } }
  end

  def calc_normalized_indegree_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, EMAIL_IN, group_id, pin_id)
  end

  def calc_normalized_outdegree_for_specified_matrix(snapshot_id, matrix_name, group_id = NO_GROUP, pin_id = NO_PIN)
    calc_normalized_degree_for_specified_matrix(snapshot_id, matrix_name, EMAIL_OUT, group_id, pin_id)
  end

  #################################  AVERAGES #######################################################
  def calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, direction)
    result_vector = (direction == EMAIL_IN) ?  calc_indeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    : calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    comp1 = find_company_by_snapshot(snapshot_id)
    company_size = get_unit_size(comp1, -1, -1)
    total_sum = result_vector.inject(0){ |memo, emp| memo + emp[:measure] }
    return -1 if company_size == 0
    (total_sum.to_f / company_size).round(2)
  end

  def calc_avg_indeg_for_specified_matrix(snapshot_id, matrix_name)
    calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, EMAIL_IN)
  end

  def calc_avg_outdeg_for_specified_matrix(snapshot_id, matrix_name)
    calc_avg_deg_for_specified_matrix(snapshot_id, matrix_name, EMAIL_OUT)
  end

  #################################  MAXIMA FUNCTIONS ################################################
  def calc_max_degree_for_specified_matrix(snapshot_id, matrix_name, direction)
    (direction == EMAIL_IN) ? calc_max_indegree_for_specified_matrix(snapshot_id, matrix_name) :
                                        calc_max_outdegree_for_specified_matrix(snapshot_id, matrix_name)
  end

  def calc_max_indegree_for_specified_matrix(snapshot_id, matrix_name)
    result_vector = calc_indeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_outdegree_for_specified_matrix(snapshot_id, matrix_name)
    result_vector = calc_outdeg_for_specified_matrix(snapshot_id, matrix_name, -1, -1)
    calc_max_vector(result_vector)
  end

  def calc_max_vector(emp_vector)
    return calc_max_in_vector_by_attribute(emp_vector, :measure)
  end

  def calc_max_in_vector_by_attribute(emp_vector, attribute)
    return emp_vector.map { |elem| elem["#{attribute}".to_sym] }.max
  end
end
