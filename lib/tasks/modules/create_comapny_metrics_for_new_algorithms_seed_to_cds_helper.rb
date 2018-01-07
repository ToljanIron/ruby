module CreateComapnyMetricsForNewAlgorithmsSeedToCdsHelper
  def create_comapny(cid)
    NetworkName.find_or_create_by!(name: 'Friendship', company_id: cid).id
    NetworkName.find_or_create_by!(name: 'Advice', company_id: cid).id
    NetworkName.find_or_create_by!(name: 'Trust', company_id: cid).id
    NetworkName.find_or_create_by!(name: 'Communication Flow', company_id: cid).id
    NetworkName.find_or_create_by!(name: 'Meeting Flow', company_id: cid).id

    ####################### Emails ############################
    spammers_id         = MetricName.find_or_create_by!(name: 'Spammers', company_id: cid).id
    blitzed_id          = MetricName.find_or_create_by!(name: 'Blitzed', company_id: cid).id
    relays_id           = MetricName.find_or_create_by!(name: 'Relays', company_id: cid).id
    ccers_id            = MetricName.find_or_create_by!(name: 'Ccers', company_id: cid).id
    cced_id             = MetricName.find_or_create_by!(name: 'Cced', company_id: cid).id
    bcced_id            = MetricName.find_or_create_by!(name: 'BCCed', company_id: cid).id
    bccers_id           = MetricName.find_or_create_by!(name: 'BCCers', company_id: cid).id
    emails_volume_id    = MetricName.find_or_create_by!(name: 'Emails Volume', company_id: cid).id

    CompanyMetric.find_or_create_by!(metric_id: spammers_id, network_id: -1, company_id: cid, algorithm_id: 700, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: blitzed_id, network_id: -1, company_id: cid, algorithm_id: 701, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: relays_id, network_id: -1, company_id: cid, algorithm_id: 702, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: ccers_id, network_id: -1, company_id: cid, algorithm_id: 703, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: cced_id, network_id: -1, company_id: cid, algorithm_id: 704, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: bcced_id, network_id: -1, company_id: cid, algorithm_id: 705, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: bccers_id, network_id: -1, company_id: cid, algorithm_id: 706, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: emails_volume_id, network_id: -1, company_id: cid, algorithm_id: 707, algorithm_type_id: 1)

    ####################### Meetings ##########################
    in_the_loop_id                      = MetricName.find_or_create_by!(name: 'In the loop', company_id: cid).id
    rejecters_id                        = MetricName.find_or_create_by!(name: 'Rejecters', company_id: cid).id
    routiners_id                        = MetricName.find_or_create_by!(name: 'Routiners', company_id: cid).id
    inviters_id                         = MetricName.find_or_create_by!(name: 'Inviters', company_id: cid).id
    observers_id                        = MetricName.find_or_create_by!(name: 'Observers', company_id: cid).id
    avg_meeting_participants_gauge_id   = MetricName.find_or_create_by!(name: 'Participants', company_id: cid).id
    avg_time_spent_in_meetings_gauge_id = MetricName.find_or_create_by!(name: 'Time spent in meetings - Gauge', company_id: cid).id
    avg_time_spent_in_meetings_measure_id = MetricName.find_or_create_by!(name: 'Time spent in meetings - Measure', company_id: cid).id


    CompanyMetric.find_or_create_by!(metric_id: in_the_loop_id, network_id: -1, company_id: cid, algorithm_id: 800, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: rejecters_id, network_id: -1, company_id: cid, algorithm_id: 801, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: routiners_id, network_id: -1, company_id: cid, algorithm_id: 802, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: inviters_id, network_id: -1, company_id: cid, algorithm_id: 803, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: observers_id, network_id: -1, company_id: cid, algorithm_id: 804, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: avg_meeting_participants_gauge_id, network_id: -1, company_id: cid, algorithm_id: 805, algorithm_type_id: 5)
    CompanyMetric.find_or_create_by!(metric_id: avg_time_spent_in_meetings_gauge_id, network_id: -1, company_id: cid, algorithm_id: 806, algorithm_type_id: 5)
    CompanyMetric.find_or_create_by!(metric_id: avg_time_spent_in_meetings_measure_id, network_id: -1, company_id: cid, algorithm_id: 807, algorithm_type_id: 1)

    ####################### Interfaces ########################
    closeness_level_gauge_id = MetricName.find_or_create_by!(name: 'Closeness Level', company_id: cid).id
    synergy_level_gauge_id   = MetricName.find_or_create_by!(name: 'Synergy Level', company_id: cid).id

    bottleneck_id            = MetricName.find_or_create_by!(name: 'Bottlenecks', company_id: cid).id
    internal_champions_id    = MetricName.find_or_create_by!(name: 'Internal Champions', company_id: cid).id
    connectors_id            = MetricName.find_or_create_by!(name: 'Connectors', company_id: cid).id
    isolate_id               = MetricName.find_or_create_by!(name: 'Information Isolates', company_id: cid).id
    deadends_id              = MetricName.find_or_create_by!(name: 'Deadends', company_id: cid).id

    CompanyMetric.find_or_create_by!(metric_id: closeness_level_gauge_id, network_id: -1, company_id: cid, algorithm_id: 200, algorithm_type_id: 5)
    CompanyMetric.find_or_create_by!(metric_id: synergy_level_gauge_id, network_id: -1, company_id: cid, algorithm_id: 201, algorithm_type_id: 5)

    CompanyMetric.find_or_create_by!(metric_id: bottleneck_id, network_id: -1, company_id: cid, algorithm_id: 203, algorithm_type_id: 2, active: true)
    CompanyMetric.find_or_create_by!(metric_id: internal_champions_id, network_id: -1, company_id: cid, algorithm_id: 204, algorithm_type_id: 1, active: true)
    CompanyMetric.find_or_create_by!(metric_id: isolate_id, network_id: -1, company_id: cid, algorithm_id: 205, algorithm_type_id: 1, active: true)
    CompanyMetric.find_or_create_by!(metric_id: connectors_id, network_id: -1, company_id: cid, algorithm_id: 206, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: deadends_id, network_id: -1, company_id: cid, algorithm_id: 207, algorithm_type_id: 1)


    ####################### Dynamics  #########################
    external_recievers_id  = MetricName.find_or_create_by!(name: 'External Receivers', company_id: cid).id
    external_senders_id    = MetricName.find_or_create_by!(name: 'External Senders', company_id: cid).id

    CompanyMetric.find_or_create_by!(metric_id: external_recievers_id, network_id: -1, company_id: cid, algorithm_id: 709, algorithm_type_id: 1)
    CompanyMetric.find_or_create_by!(metric_id: external_senders_id, network_id: -1, company_id: cid, algorithm_id: 710, algorithm_type_id: 1)
  end
end
