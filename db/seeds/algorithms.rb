# frozen_string_literal: true

############## Emails #####################
Algorithm.find_or_create_by!(id: 700, name: 'spammers_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 701, name: 'blitzed_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 702, name: 'relays_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 703, name: 'ccers_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 704, name: 'cced_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 705, name: 'undercover_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 706, name: 'politicos_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 707, name: 'emails_volume_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 709, name: 'avg_number_of_recipients', algorithm_type_id: 9, algorithm_flow_id: 2, use_group_context: false)

############## Meetings ####################
Algorithm.find_or_create_by!(id: 800, name: 'in_the_loop_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 801, name: 'rejecters_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 802, name: 'routiners_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 803, name: 'inviters_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 804, name: 'observers_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 805, name: 'num_of_ppl_in_meetings_gauge', algorithm_type_id: 5, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 806, name: 'avg_time_spent_in_meetings_gauge', algorithm_type_id: 5, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 807, name: 'time_spent_in_meetings_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 808, name: 'recurring_meetings_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)

############# Dynamics ###############
Algorithm.find_or_create_by!(id: 200, name: 'closeness_level_gauge', algorithm_type_id: 5)
Algorithm.find_or_create_by!(id: 201, name: 'synergy_level_gauge', algorithm_type_id: 5)

Algorithm.find_or_create_by!(id: 203, name: 'calculate_bottlenecks', algorithm_type_id: 1, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD, use_group_context: false)
Algorithm.find_or_create_by!(id: 204, name: 'internal_champions', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 205, name: 'calculate_information_isolate_to_args', algorithm_type_id: 1, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD, use_group_context: false)
Algorithm.find_or_create_by!(id: 206, name: 'calculate_connectors', algorithm_type_id: 1, algorithm_flow_id: 1, use_group_context: false)
Algorithm.find_or_create_by!(id: 207, name: 'deadends_measure', algorithm_type_id: 1, algorithm_flow_id: 2, use_group_context: false)

############## Interfaces   ###############
Algorithm.find_or_create_by!(id: 300, name: 'external_receivers_volume', algorithm_type_id: 5, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 301, name: 'external_senders_volume', algorithm_type_id: 5, algorithm_flow_id: 2, use_group_context: false)
Algorithm.find_or_create_by!(id: 302, name: 'internal_traffic_volume', algorithm_type_id: 5, algorithm_flow_id: 2, use_group_context: false)

############## Interact ####################
Algorithm.find_or_create_by!(id: 601, name: 'interact_indegree',  algorithm_type_id: 8, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 602, name: 'interact_outdegree', algorithm_type_id: 8, algorithm_flow_id: 1)
