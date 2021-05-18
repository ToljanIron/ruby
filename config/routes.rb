Workships::Application.routes.draw do


  resources :sessions, only: [:new, :create, :destroy, :forgot_password, :set_password, :signin]

  root to: redirect('/v2')

  get   '/robots.txt',                  to: 'application#robots'
  get   '/signin',                      to: 'sessions#signin'
  get   '/qqq',                         to: 'utils#qqq'

  get   '/get_questionnaires',             to: 'mobile/questionnaire#get_questionnaires_for_settings_tab'
  get   '/get_questionnaire_participants', to: 'mobile/questionnaire#get_questionnaire_participants'

  post  '/API/signin',                to: 'sessions#api_signin'
  get   '/API/signout',               to: 'sessions#destroy'

  post  '/API/import_emails',         to: 'raw_data_entries#import_emails'
  post  '/API/import_meetings',       to: 'raw_meetings_data#import_meetings'

  ############ mobile ###############

  get   '/mobile',                     to: 'mobile/companies#show'
  get   '/questionnaire',              to: 'application#show_mobile'
  get   'get_questionnaire_employees', to: 'questionnaire#all_employees'
  post  'get_next_question',           to: 'questionnaire#get_next_question'
  post  'close_question',              to: 'questionnaire#close_question'
  post  'update_replies',              to: 'questionnaire#update_question_replies'
  get   'keep_alive',                  to: 'questionnaire#keep_alive'

  get   'question/active_employess', to: 'mobile/questionnaire#active_employees'
  post  'receive_sms', to: 'sms#receive_and_respond'

  ######################## admin ##################################
  post '/0dWb7K61dIyxHkXkALixfEwKIEG7H9/create_company',     to: 'backoffice#create_company'
  post '/0dWb7K61dIyxHkXkALixfEwKIEG7H9/create_user',        to: 'backoffice#create_user'
  get  '/0dWb7K61dIyxHkXkALixfEwKIEG7H9/show_users',         to: 'backoffice#show_users'
  get  '/0dWb7K61dIyxHkXkALixfEwKIEG7H9/show_companies',     to: 'backoffice#show_companies'
  post '/0dWb7K61dIyxHkXkALixfEwKIEG7H9/change_user_company',to: 'backoffice#change_user_company'

  ######################## onprem setup ############################
  get  '/sa_setup',                         to: 'sa_setup#base'
  get  '/sa_setup/form_error',              to: 'sa_setup#form_error'
  get  '/sa_setup/microsoft_auth',          to: 'sa_setup#microsoft_auth'
  get  '/sa_setup/microsoft_auth_redirect', to: 'sa_setup#microsoft_auth_redirect'
  get  '/sa_setup/microsoft_auth_back',     to: 'sa_setup#microsoft_auth_back'
  get  '/sa_setup/log_files_location',      to: 'sa_setup#log_files_location'
  post '/sa_setup/log_files_location',      to: 'sa_setup#log_files_location_set'
  get  '/sa_setup/log_files_location_verification', to: 'sa_setup#log_files_location_verification'
  get  '/sa_setup/gpg_passphrase',          to: 'sa_setup#gpg_passphrase'
  post '/sa_setup/gpg_passphrase',          to: 'sa_setup#gpg_passphrase_set'
  get  '/sa_setup/it_done',                 to: 'sa_setup#it_done'
  get  '/sa_setup/system_definitions',      to: 'sa_setup#upload_company'
  post '/sa_setup/employees_excel',         to: 'sa_setup#employees_excel'
  get  '/sa_setup/standby_or_push',         to: 'sa_setup#standby_or_push'
  get  '/sa_setup/goto_system',             to: 'sa_setup#goto_system'
  get  '/sa_setup/collect_now',             to: 'sa_setup#collect_now'
  get  '/sa_setup/push',                    to: 'sa_setup#push'
  get  '/sa_setup/retry_push',              to: 'sa_setup#collect_again'
  get  '/sa_setup/get_push_state',          to: 'sa_setup#get_push_state'

  ############## Interact ##########################################
  get  '/interact_backoffice',                          to: 'interact_backoffice#questionnaire'
  get  '/interact_backoffice/get_questionnaires',       to: 'interact_backoffice#get_questionnaires'
  get  '/interact_backoffice/questionnaire',            to: 'interact_backoffice#questionnaire'
  post '/interact_backoffice/questionnaire_update',     to: 'interact_backoffice#questionnaire_update'
  post '/interact_backoffice/questionnaire_delete',     to: 'interact_backoffice#questionnaire_delete'
  get  '/interact_backoffice/questionnaire_create',     to: 'interact_backoffice#questionnaire_create'
  post '/interact_backoffice/quesitonnaire_run',        to: 'interact_backoffice#questionnaire_run'
  post '/interact_backoffice/quesitonnaire_close',      to: 'interact_backoffice#questionnaire_close'
  post '/interact_backoffice/quesitonnaire_copy',       to: 'interact_backoffice#questionnaire_copy'
  post '/interact_backoffice/update_test_participant',  to: 'interact_backoffice#update_test_participant'
  get  '/interact_backoffice/get_questions',            to: 'interact_backoffice#get_questions'
  post '/interact_backoffice/questions_create',         to: 'interact_backoffice#question_create'
  post '/interact_backoffice/questions_update',         to: 'interact_backoffice#question_update'
  post '/interact_backoffice/questions_reorder',        to: 'interact_backoffice#questions_reorder'
  post '/interact_backoffice/questions_delete',         to: 'interact_backoffice#question_delete'
  get  '/interact_backoffice/get_participants',         to: 'interact_backoffice#participants'
  get  '/interact_backoffice/get_participant_status',   to: 'interact_backoffice#participant_status'
  get  '/interact_backoffice/get_questionnaire_status',   to: 'interact_backoffice#questionnaire_status'
  post '/interact_backoffice/participants_create',      to: 'interact_backoffice#participants_create'
  post '/interact_backoffice/participants_update',      to: 'interact_backoffice#participants_update'
  post '/interact_backoffice/participants_delete',      to: 'interact_backoffice#participants_delete'
  post '/interact_backoffice/participant_reset',        to: 'interact_backoffice#participant_reset'
  post '/interact_backoffice/participant_resend',       to: 'interact_backoffice#participant_resend'
  post '/interact_backoffice/close_participant_questionnaire',       to: 'interact_backoffice#close_participant_questionnaire'
  post '/interact_backoffice/set_active_questionnaire_question', to: 'interact_backoffice#set_active_questionnaire_question'
  get  '/interact_backoffice/participants_filter',      to: 'interact_backoffice#participants_filter'
  get  '/interact_backoffice/participants_bulk_actions',to: 'interact_backoffice#participants_bulk_actions'
  post '/interact_backoffice/participants_load',        to: 'interact_backoffice#participants_load'
  get  '/interact_backoffice/participants_get_emps',    to: 'interact_backoffice#participants_get_emps'
  get  '/interact_backoffice/reports',                  to: 'interact_backoffice#reports'
  get  '/interact_backoffice/reports_network',          to: 'interact_backoffice#reports_network'
  get  '/interact_backoffice/reports_measures',         to: 'interact_backoffice#reports_measures'
  get  '/interact_backoffice/reports_survey',         to: 'interact_backoffice#reports_survey'
  get  '/interact_backoffice/reports_bidirectional_network', to: 'interact_backoffice#reports_bidirectional_network'
  get  '/interact_backoffice/reports_summary',          to: 'interact_backoffice#reports_summary'

  post '/interact_backoffice/actions_img_upload',      to: 'interact_backoffice#img_upload'
  post '/interact_backoffice/actions_img_bulk_upload', to: 'interact_backoffice#actions_img_bulk_upload'
  get  '/interact_backoffice/actions_download_sample' ,to: 'interact_backoffice#download_sample'
  get  '/interact_backoffice/actions_participants_status' ,to: 'interact_backoffice#download_participants_status'
  post '/interact_backoffice/actions_upload_participants' ,to: 'interact_backoffice#upload_participants'

  post '/interact_backoffice/simulate_replies',        to: 'interact_backoffice#simulate_results'

  post '/interact_backoffice/remove_participants',      to: 'interact_backoffice#remove_participants'
  post '/interact_backoffice/save_params',      to: 'interact_backoffice#update_data_mapping'
  get '/interact_backoffice/get_factors',               to: 'interact_backoffice#get_factors'

  ############################ v3 ############################

  post 'v3/setting/update_user_info'         ,to: 'settings#update_user_info'
  post 'v3/setting/update_security_settings' ,to: 'settings#update_security_settings'
  post 'v3/setting/edit_password'            ,to: 'settings#edit_password'
  get 'v3/get_config_params'                 ,to: 'settings#get_config_params'

  get 'v3/jobs_status'                       ,to: 'jobs#jobs_status'

  get 'v3/get_snapshots'                     ,to: 'snapshots#get_snapshots'
  get 'v3/get_time_picker_snapshots'         ,to: 'snapshots#get_time_picker_snapshots'

  get 'v3/get_groups'                        ,to: 'groups#groups'
  get 'v3/get_user_details'                  ,to: 'users#user_details'

  # Emails
  get 'v3/get_emails_time_picker_data'       ,to: 'measures#get_emails_time_picker_data'
  get 'v3/get_email_scores'                  ,to: 'measures#get_email_scores'
  get 'v3/get_employees_emails_scores'       ,to: 'measures#get_employees_emails_scores'
  get 'v3/get_email_stats'                   ,to: 'measures#get_email_stats'
  get 'v3/get_emails_excel_report'           ,to: 'reports#get_emails_excel_report'

  # Meetings
  get 'v3/get_meetings_time_picker_data'     ,to: 'measures#get_meetings_time_picker_data'
  get 'v3/get_meetings_scores'               ,to: 'measures#get_meetings_scores'
  get 'v3/get_meetings_stats'                ,to: 'measures#get_meetings_stats'
  get 'v3/get_employees_meetings_scores'     ,to: 'measures#get_employees_meetings_scores'

  # Dynamics
  get 'v3/get_collaboration_stats'           ,to: 'measures#get_dynamics_stats'
  get 'v3/get_dynamics_time_picker_data'     ,to: 'measures#get_dynamics_time_picker_data'
  get 'v3/get_dynamics_scores'               ,to: 'measures#get_dynamics_scores'
  get 'v3/get_dynamics_employee_scores'      ,to: 'measures#get_dynamics_employee_scores'
  get 'v3/get_dynamics_excel_report'         ,to: 'reports#get_dynamics_excel_report'
  get 'v3/get_dynamics_map'                  ,to: 'network_snapshot_data#get_dynamics_map'
  get 'v3/get_dynamics_employee_map'         ,to: 'network_snapshot_data#get_dynamics_employee_map'

  # Interfaces
  get 'v3/get_interfaces_time_picker_data'   ,to: 'measures#get_interfaces_time_picker_data'
  get 'v3/get_interfaces_scores'             ,to: 'measures#get_interfaces_scores'
  get 'v3/get_interfaces_map'                ,to: 'network_snapshot_data#get_interfaces_map'
  get 'v3/get_interfaces_stats'              ,to: 'measures#get_interfaces_stats'

  # Alerts
  get 'v3/get_alerts'                        ,to: 'alerts#get_alerts'
  post 'v3/acknowledge_alert'                ,to: 'alerts#acknowledge_alert'

  # Interact
  get 'v3/get_questionnaire_data'            ,to: 'interact#get_question_data'
  get 'v3/get_map_data'                      ,to: 'interact#get_map'
end
