# frozen_string_literal: true

############## Old Algos ##################
Algorithm.find_or_create_by!(id: 16,  name: 'in_the_loop_to_args', algorithm_type_id: 1, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 21,  name: 'politically_active_to_args')
Algorithm.find_or_create_by!(id: 29,  name: 'collaboration', algorithm_type_id: 3, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 60,  name: 'collaboration', algorithm_type_id: 1, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 74,  name: 'most_bypassed_managers', algorithm_type_id: 2, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 81,  name: 'centrality_to_args', algorithm_type_id: 3, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 101, name: 'calculate_powerful_non_managers_to_args', algorithm_type_id: 2, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 102, name: 'calculate_non_reciprocity_between_employees_to_args', algorithm_type_id: 2, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 113, name: 'calculate_non_reciprocity_between_employees_explore_to_args', algorithm_type_id: 3, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 141, name: 'flag_sinks', algorithm_type_id: 2, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 144, name: 'no_of_emails_sent_for_explore', algorithm_type_id: 3, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 149, name: 'avg_subject_length', algorithm_type_id: 5, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 150, name: 'avg_subject_length_to_explore', algorithm_type_id: 5, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 154, name: 'political_power_flag', algorithm_type_id: 2, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 157, name: 'average_no_of_attendees_gauge', algorithm_type_id: 5)
Algorithm.find_or_create_by!(id: 158, name: 'proportion_time_spent_on_meetings_gauge', algorithm_type_id: 5)
Algorithm.find_or_create_by!(id: 159, name: 'proportion_of_managers_never_in_meetings_gauge', algorithm_type_id: 5)

############## Emails #####################
Algorithm.find_or_create_by!(id: 700, name: 'spammers_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 701, name: 'blitzed_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 702, name: 'relays_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 703, name: 'ccers_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 704, name: 'cced_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 705, name: 'undercover_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 706, name: 'politicos_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 707, name: 'emails_volume_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 708, name: 'deadends_measure', algorithm_type_id: 1, algorithm_flow_id: 2)

############## Meetings ####################
Algorithm.find_or_create_by!(id: 800, name: 'in_the_loop_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 801, name: 'rejecters_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 802, name: 'routiners_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 803, name: 'inviters_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 804, name: 'observers_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 805, name: 'num_of_ppl_in_meetings_gauge', algorithm_type_id: 5, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 806, name: 'avg_time_spent_in_meetings_gauge', algorithm_type_id: 5, algorithm_flow_id: 2)

############## Interfaces ###############
Algorithm.find_or_create_by!(id: 200, name: 'closeness_level_gauge', algorithm_type_id: 5)
Algorithm.find_or_create_by!(id: 201, name: 'synergy_level_gauge', algorithm_type_id: 5)

Algorithm.find_or_create_by!(id: 203, name: 'calculate_bottlenecks', algorithm_type_id: 1, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 204, name: 'internal_champions', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 205, name: 'calculate_information_isolate_to_args', algorithm_type_id: 1, algorithm_flow_id: 1, meaningful_sqew: Algorithm::SCORE_SKEW_HIGH_IS_BAD)
Algorithm.find_or_create_by!(id: 206, name: 'calculate_connectors', algorithm_type_id: 1, algorithm_flow_id: 1)

############## Dynamics   ###############
Algorithm.find_or_create_by!(id: 300, name: 'external_receivers_measure', algorithm_type_id: 1, algorithm_flow_id: 2)
Algorithm.find_or_create_by!(id: 310, name: 'external_senders_measure', algorithm_type_id: 1, algorithm_flow_id: 2)

############## Interact ####################
Algorithm.find_or_create_by!(id: 601, name: 'interact_indegree',  algorithm_type_id: 8, algorithm_flow_id: 1)
Algorithm.find_or_create_by!(id: 602, name: 'interact_outdegree', algorithm_type_id: 8, algorithm_flow_id: 1)
