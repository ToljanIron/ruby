Workships::Application.routes.draw do


  #get 'backend_v_two/load_csv'

  #resources :company_configuration_tables
  #get 'log/getlog'
  #mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  #resources :users
  #resources :app_viewrs
  resources :sessions, only: [:new, :create, :destroy, :forgot_password, :set_password, :signin]

  root to: redirect('/v2')

  #get   '/questionnaire/',              to: 'application#show_mobile'
  get   '/robots.txt',                  to: 'application#robots'
  get   '/signin',                      to: 'sessions#signin'
  #get   '/signout',                     to: 'sessions#destroy'
  #get   '/v2/backend',                  to: 'backend_v_two#load_csv'
  #get   '/backend',                     to: 'utils#backend'
  #post  '/upload_csv',                  to: 'utils#upload_csv_v2'
  #post  '/upload_excel',                to: 'utils#upload_excel'
  get   '/qqq',                         to: 'utils#qqq'

  get   '/get_questionnaires',             to: 'mobile/questionnaire#get_questionnaires_for_settings_tab'
  get   '/get_questionnaire_participants', to: 'mobile/questionnaire#get_questionnaire_participants'

  post    '/API/signin',                to: 'sessions#api_signin'
  get     '/API/signout',               to: 'sessions#destroy'

  post    '/API/import_emails',         to: 'raw_data_entries#import_emails'

  #post    '/API/export_to_csv',         to: 'clients#export_to_csv'
  #post    '/API/init_report_xls',       to: 'utils#init_report_xls'
  #get     '/API/export_xls',            to: 'utils#export_xls'
  #get     '/API/download_interact',     to: 'utils#download_interact_report'

  post    '/API/import_meetings',       to: 'raw_meetings_data#import_meetings'

  ############ mobile ###############

  get   '/mobile',          to: 'mobile/companies#show'
  get   '/questionnaire',   to: 'application#show_mobile'
  get    'get_questionnaire_employees' => 'mobile/employees#all_employees'
  post   'get_next_question' => 'mobile/questions#next'

  post  'question/create' => 'mobile/questions#create'
  post  'question/remove' => 'mobile/questions#remove'

  post  'questionnaire/send_questionnaire'             => 'mobile/questionnaire#send_questionnaire'
  post  'questionnaire/resend_questionnaire_for_emp'   => 'mobile/questionnaire#send_questionnaire_for_emp'
  post  'questionnaire/reset_questionnaire_for_emp'    => 'mobile/questionnaire#reset_questionnaire_for_emp'
  post  'questionnaire/generate_questionnaire_report'  => 'mobile/questionnaire#generate_questionnaire_report'
  post  'questionnaire/send_questionnaire_to_all_ajax' => 'mobile/questionnaire#send_questionnaire_to_all_ajax'
  post  'questionnaire/send_questionnaire_desktop'     => 'mobile/questionnaire#send_questionnaire_desktop'
  post  'questionnaire/download_csv'                   => 'mobile/questionnaire#download_csv'
  get   'questionnaire/capture_snapshot'               ,to:  'mobile/questionnaire#capture_quesitonnaire_in_snapshot'
  get   'questionnaire/get_questionnaire_state'        ,to:  'mobile/questionnaire#get_questionnaires_state'

  get   'keep_alive'     => 'mobile/mobile#keep_alive'

  post  'questionnaire_questions/update', to: 'mobile/questionnaire_questions#update_questionnaire_question'

  get  'question/active_employess', to: 'mobile/questionnaire#active_employees'

  post 'v2/mobile_questionnaire/update' , to: 'mobile/questionnaire#update_questionnaire'
  post 'v2/mobile_questionnaire/create', to: 'mobile/questionnaire#create_new_questionnaire'

  post 'receive_sms', to: 'sms#receive_and_respond'

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

  # Alerts
  get 'v3/get_alerts'                        ,to: 'alerts#get_alerts'
  post 'v3/acknowledge_alert'                ,to: 'alerts#acknowledge_alert'
end
