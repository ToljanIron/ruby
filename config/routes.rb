Workships::Application.routes.draw do


  resources :sessions, only: [:new, :create, :destroy, :forgot_password, :set_password, :signin]

  root to: redirect('/v2')

  get   '/robots.txt',                  to: 'application#robots'
  get   '/signin',                      to: 'sessions#signin'
  get   '/qqq',                         to: 'utils#qqq'

  get   '/get_questionnaires',             to: 'mobile/questionnaire#get_questionnaires_for_settings_tab'
  get   '/get_questionnaire_participants', to: 'mobile/questionnaire#get_questionnaire_participants'

  post    '/API/signin',                to: 'sessions#api_signin'
  get     '/API/signout',               to: 'sessions#destroy'

  post    '/API/import_emails',         to: 'raw_data_entries#import_emails'
  post    '/API/import_meetings',       to: 'raw_meetings_data#import_meetings'

  ############ mobile ###############

  get   '/mobile',          to: 'mobile/companies#show'
  get   '/questionnaire',   to: 'application#show_mobile'
  get    'get_questionnaire_employees' => 'mobile/employees#all_employees'
  post   'get_next_question' => 'mobile/questions#next'

  get   'keep_alive'     => 'mobile/mobile#keep_alive'
  get  'question/active_employess', to: 'mobile/questionnaire#active_employees'
  post 'receive_sms', to: 'sms#receive_and_respond'

  get '/interact_backoffice',                      to: 'interact_backoffice#questionnaire'
  get '/interact_backoffice/get_questionnaires',   to: 'interact_backoffice#get_questionnaires'
  get '/interact_backoffice/questionnaire',        to: 'interact_backoffice#questionnaire'
  post '/interact_backoffice/questionnaire_update',to: 'interact_backoffice#questionnaire_update'
  post '/interact_backoffice/questionnaire_delete',to: 'interact_backoffice#questionnaire_delete'
  get '/interact_backoffice/questionnaire_create', to: 'interact_backoffice#questionnaire_create'
  get '/interact_backoffice/test',                 to: 'interact_backoffice#test'
  get '/interact_backoffice/test_update',          to: 'interact_backoffice#test_update'
  get '/interact_backoffice/get_questions',        to: 'interact_backoffice#get_questions'
  post '/interact_backoffice/questions_create',    to: 'interact_backoffice#question_create'
  post '/interact_backoffice/questions_update',    to: 'interact_backoffice#question_update'
  post '/interact_backoffice/questions_delete',    to: 'interact_backoffice#question_delete'
  get '/interact_backoffice/get_participants',     to: 'interact_backoffice#participants'
  post '/interact_backoffice/participants_create', to: 'interact_backoffice#participants_create'
  post '/interact_backoffice/participants_update', to: 'interact_backoffice#participants_update'
  post '/interact_backoffice/participants_delete', to: 'interact_backoffice#participants_delete'
  get '/interact_backoffice/participants_filter',  to: 'interact_backoffice#participants_filter'
  get '/interact_backoffice/participants_bulk_actions', to: 'interact_backoffice#participants_bulk_actions'
  post '/interact_backoffice/participants_load',   to: 'interact_backoffice#participants_load'
  get '/interact_backoffice/reports',              to: 'interact_backoffice#reports'
  get '/interact_backoffice/reports_network',      to: 'interact_backoffice#reports_network'
  get '/interact_backoffice/reports_measures',     to: 'interact_backoffice#reports_measures'
  get '/interact_backoffice/reports_bidirectional_network', to: 'interact_backoffice#reports_bidirectional_network'
  get '/interact_backoffice/reports_summary',      to: 'interact_backoffice#reports_summary'

  post '/interact_backoffice/actions_img_upload',     to: 'interact_backoffice#img_upload'
  post '/interact_backoffice/actions_img_bulk_upload',to: 'interact_backoffice#actions_img_bulk_upload'
  get  '/interact_backoffice/actions_download_sample' ,to: 'interact_backoffice#download_sample'
  post '/interact_backoffice/actions_upload_participants', to: 'interact_backoffice#upload_participants'

  ############################ v3 ############################

  post 'v3/setting/update_user_info'         ,to: 'settings#update_user_info'
  post 'v3/setting/update_security_settings' ,to: 'settings#update_security_settings'
  post 'v3/setting/edit_password'            ,to: 'settings#edit_password'
  get 'v3/get_config_params'                 ,to: 'settings#get_config_params'

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
end
