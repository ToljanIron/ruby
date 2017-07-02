module CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper
  def create_comapny(cid)
    friendship_network_id    = NetworkName.find_or_create_by(name: 'Friendship', company_id: cid).id
    advice_network_id        = NetworkName.find_or_create_by(name: 'Advice', company_id: cid).id
    trust_network_id         = NetworkName.find_or_create_by(name: 'Trust', company_id: cid).id
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id

    most_bypassed_manager_id = MetricName.find_or_create_by(name: 'Most Bypassed Manager', company_id: cid).id
    collaboration_metric_id  = MetricName.find_or_create_by(name: 'Collaboration', company_id: cid).id
    in_the_loop_id           = MetricName.find_or_create_by(name: 'In the loop', company_id: cid).id
    bottleneck_id            = MetricName.find_or_create_by(name: 'Bottleneck', company_id: cid).id
    spammers_id              = MetricName.find_or_create_by(name: 'Spammers', company_id: cid).id
    blitzed_id               = MetricName.find_or_create_by(name: 'Blitzed', company_id: cid).id
    relays_id                = MetricName.find_or_create_by(name: 'Relays', company_id: cid).id
    ccers_id                 = MetricName.find_or_create_by(name: 'Ccers', company_id: cid).id
    cced_id                  = MetricName.find_or_create_by(name: 'Cced', company_id: cid).id
    undercover_id            = MetricName.find_or_create_by(name: 'Undercover', company_id: cid).id
    politicos_id             = MetricName.find_or_create_by(name: 'Politicos', company_id: cid).id   
    emails_volume_id         = MetricName.find_or_create_by(name: 'Emails Volume', company_id: cid).id   
    deadends_id              = MetricName.find_or_create_by(name: 'Deadends', company_id: cid).id   
    
    in_the_loop_id           = MetricName.find_or_create_by(name: 'In the loop', company_id: cid).id
    rejecters_id             = MetricName.find_or_create_by(name: 'Rejecters', company_id: cid).id
    routiners_id             = MetricName.find_or_create_by(name: 'Routiners', company_id: cid).id
    inviters_id              = MetricName.find_or_create_by(name: 'Inviters', company_id: cid).id
    observers_id             = MetricName.find_or_create_by(name: 'Observers', company_id: cid).id

    CompanyMetric.find_or_create_by(metric_id: collaboration_metric_id, network_id: communication_network_id, company_id: cid, algorithm_id: 29, algorithm_type_id: 3)
    CompanyMetric.find_or_create_by(metric_id: most_bypassed_manager_id, network_id: friendship_network_id, company_id: cid, algorithm_id: 74, algorithm_type_id: 2, active: false)
    CompanyMetric.find_or_create_by(metric_id: in_the_loop_id, network_id: communication_network_id, company_id: cid, algorithm_id: 16, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: collaboration_metric_id, network_id: communication_network_id, company_id: cid, algorithm_id: 60, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: bottleneck_id, network_id: communication_network_id, company_id: cid, algorithm_id: 130, algorithm_type_id: 2, active: false)

    CompanyMetric.find_or_create_by(metric_id: spammers_id, network_id: communication_network_id, company_id: cid, algorithm_id: 700, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: blitzed_id, network_id: communication_network_id, company_id: cid, algorithm_id: 701, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: relays_id, network_id: communication_network_id, company_id: cid, algorithm_id: 702, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: ccers_id, network_id: communication_network_id, company_id: cid, algorithm_id: 703, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: cced_id, network_id: communication_network_id, company_id: cid, algorithm_id: 704, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: undercover_id, network_id: communication_network_id, company_id: cid, algorithm_id: 705, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: politicos_id, network_id: communication_network_id, company_id: cid, algorithm_id: 706, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: emails_volume_id, network_id: communication_network_id, company_id: cid, algorithm_id: 707, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: deadends_id, network_id: communication_network_id, company_id: cid, algorithm_id: 708, algorithm_type_id: 1)

    CompanyMetric.find_or_create_by(metric_id: in_the_loop_id, network_id: -1, company_id: cid, algorithm_id: 800, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: rejecters_id, network_id: -1, company_id: cid, algorithm_id: 801, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: routiners_id, network_id: -1, company_id: cid, algorithm_id: 802, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: inviters_id, network_id: -1, company_id: cid, algorithm_id: 803, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by(metric_id: observers_id, network_id: -1, company_id: cid, algorithm_id: 804, algorithm_type_id: 1)
  end

  ############## V3 gauges ###############################################################

  def create_new_seed_for_gauge_num_of_ppl_in_meetings(cid)
    meeting_network_id = NetworkName.find_or_create_by(name: 'Meeting Flow', company_id: cid).id
    avg_meeting_participants_gauge_id = MetricName.find_or_create_by!(name: 'Participants', company_id: cid).id
    cm = CompanyMetric.find_or_create_by!(metric_id: avg_meeting_participants_gauge_id,
                                          network_id: meeting_network_id,
                                          company_id: cid,
                                          algorithm_id: 806,
                                          algorithm_type_id: 5)
  end

  ########################################################################################

  def create_new_seed_for_sinks(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    sinks_metric_id = MetricName.find_or_create_by(name: 'calculate_sinks_flag', company_id: cid).id
    CompanyMetric.find_or_create_by(metric_id: sinks_metric_id, network_id: communication_network_id, company_id: cid, algorithm_id: 141, algorithm_type_id: 2, active: false)
  end

  def create_new_seed_bottlenecks(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    CompanyMetric.find_or_create_by(metric_id: advice_metric_id, network_id: communication_network_id, company_id: cid, algorithm_id: 130, algorithm_type_id: 2)
  end

  def create_new_seed_for_non_reciprocity(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    non_reciprocity_metric_id = MetricName.find_or_create_by(name: 'non reciprocity', company_id: cid).id
    CompanyMetric.find_or_create_by(metric_id: non_reciprocity_metric_id, network_id: communication_network_id, company_id: cid, algorithm_id: 102, algorithm_type_id: 2, active: false)
  end

  def create_new_seed_for_political_power(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    political_power_metric_id = MetricName.find_or_create_by(name: 'political power', company_id: cid).id
    CompanyMetric.find_or_create_by(
      metric_id: political_power_metric_id,
      network_id: communication_network_id,
      company_id: cid,
      algorithm_id: 154,
      algorithm_type_id: 2)
  end

  def create_new_seed_for_gauge_sinks(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    sinks_gauge_id = MetricName.find_or_create_by!(name: 'sinks_gauge', company_id: cid).id
    cm = CompanyMetric.find_or_create_by!(metric_id: sinks_gauge_id,
                                          network_id: communication_network_id,
                                          company_id: cid,
                                          algorithm_id: 147,
                                          algorithm_type_id: 5)
  end

  def create_new_seed_for_gauge_information_isolate(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    information_isolate_gauge_id = MetricName.find_or_create_by!(name: 'information_isolate_gauge', company_id: cid).id
    cm = CompanyMetric.find_or_create_by!(metric_id: information_isolate_gauge_id,
                                          network_id: communication_network_id,
                                          company_id: cid,
                                          algorithm_id: 152,
                                          algorithm_type_id: 5)
  end

  def create_new_seed_for_gauge_political_power(cid)
      communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
      political_power_flag_hidden_gauge_id = MetricName.find_or_create_by!(name: 'political_power_flag_hidden_gauge', company_id: cid).id
      cm = CompanyMetric.find_or_create_by!(metric_id: political_power_flag_hidden_gauge_id,
                                            network_id: communication_network_id,
                                            company_id: cid,
                                            algorithm_id: 156,
                                            algorithm_type_id: 5)
  end

  def create_new_seed_for_gauge_non_reciprocity(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    non_reciprocity_gauge_id = MetricName.find_or_create_by!(name: 'non_reciprocity_gauge', company_id: cid).id
    CompanyMetric.find_or_create_by!(metric_id: non_reciprocity_gauge_id,
                                     network_id: communication_network_id,
                                     company_id: cid,
                                     algorithm_id: 153,
                                     algorithm_type_id: 5)
  end

  def create_new_seed_for_average_no_of_attendees(cid)
    meeting_network_id = NetworkName.find_or_create_by(name: 'Meeting Flow', company_id: cid).id #Check which network it belongs to
    average_number_of_attendees_gauge_id = MetricName.find_or_create_by!(name: 'average_number_of_attendees', company_id: cid).id
    CompanyMetric.find_or_create_by!(metric_id: average_number_of_attendees_gauge_id,
                                     network_id: meeting_network_id,
                                     company_id: cid,
                                     algorithm_id: 157,
                                     algorithm_type_id: 5)
  end

  def create_new_seed_for_proportion_time_spent_on_meetings(cid)
    meeting_network_id = NetworkName.find_or_create_by(name: 'Meeting Flow', company_id: cid).id #Check which network it belongs to
    proportion_time_spent_on_meetings_gauge_id = MetricName.find_or_create_by!(name: 'proportion_time_spent_on_meetings', company_id: cid).id
    CompanyMetric.find_or_create_by!(metric_id: proportion_time_spent_on_meetings_gauge_id,
                                     network_id: meeting_network_id,
                                     company_id: cid,
                                     algorithm_id: 158,
                                     algorithm_type_id: 5)
  end

  def create_new_seed_for_proportion_of_managers_never_in_meetings(cid)
    meeting_network_id = NetworkName.find_or_create_by(name: 'Meeting Flow', company_id: cid).id #Check which network it belongs to
    proportion_of_managers_never_in_meetings_gauge_id = MetricName.find_or_create_by!(name: 'proportion_of_managers_never_in_meetings', company_id: cid).id
    CompanyMetric.find_or_create_by!(metric_id: proportion_of_managers_never_in_meetings_gauge_id,
                                     network_id: meeting_network_id,
                                     company_id: cid,
                                     algorithm_id: 159,
                                     algorithm_type_id: 5,
                                     active: false)
  end

  def create_new_seed_for_avg_of_subject(cid)
    communication_network_id = NetworkName.find_or_create_by(name: 'Communication Flow', company_id: cid).id
    avg_of_subject_gauge_id = MetricName.find_or_create_by!(name: 'avg_of_subject_sent', company_id: cid).id
    CompanyMetric.find_or_create_by!(metric_id: avg_of_subject_gauge_id,
                                     network_id: communication_network_id,
                                     company_id: cid,
                                     algorithm_id: 149,
                                     algorithm_type_id: 5)
  end

  def create_company_metrics_for_analyze_superposition_graph(cid)
    CompanyMetric.where(company_id: cid, algorithm_type_id: 1).each do |cm|
      relevant_id = CompanyMetric.where(algorithm_type_id: 3, company_id: cid, metric_id: cm.metric_id).first.try(:id)
      cm.update(analyze_company_metric_id: relevant_id) if relevant_id
    end
  end
end
