#!/bin/bash

CID=1
SID=1
GID=1


echo "103 - trust_friendship_centrality"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,103,$SID,true\]

echo "104 - advice_email_centrality"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,104,$SID,true\]

echo "105 - calculate_internal_faultlines_for_gender"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,105,$SID,true\]

echo "109 - density_of_network"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,109,$SID,true\]

echo "110 - calculate_external_faultlines"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,110,$SID,true\]

echo "102 - calculate_non_reciprocity_between_employees_to_args"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,102,$SID,true\]

echo "100 - calculate_information_isolate_to_args"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,100,$SID,true\]

echo "101 - calculate_powerful_non_managers_to_args"
time rake db:precalculate_metric_scores_for_custom_data_system\[$CID,$GID,-1,101,$SID,true\]
