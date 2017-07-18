Workships::Application.routes.draw do


  get 'backend_v_two/load_csv'

  resources :company_configuration_tables
  get 'log/getlog'
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  resources :users
  resources :app_viewrs
  resources :sessions, only: [:new, :create, :destroy, :forgot_password, :set_password, :signin]

  root to: redirect('/v2')

  get   '/v2',                          to: 'application#show_v2_app'

  get   '/questionnaire/',              to: 'application#show_mobile'
  get   '/robots.txt',                  to: 'application#robots'
  get   '/volume_of_emails',            to: 'measure#volume_of_emails'
  get   '/needle_for_gauge',            to: 'measure#needle_for_gauge'
  get   '/signin',                      to: 'sessions#signin'
  get   '/signout',                     to: 'sessions#destroy'
  get   '/forgot_password',             to: 'sessions#forgot_password'
  get   '/reset_password',              to: 'sessions#reset_password'
  post  '/user_forgot_password',        to: 'users#user_forgot_password'
  post  '/check_password',              to: 'sessions#check_password'
  get   '/set_password',                to: 'sessions#set_password'
  post  '/verify_password_token',       to: 'users#verify_password_token'
  post  '/update_reset_new_password',   to: 'users#update_reset_new_password'
  post  '/update_set_new_password',     to: 'users#update_set_new_password'
  get   '/email_send',                  to: 'sessions#email_send'
  get   '/employee_page',               to: 'sessions#employee_page'
  post  '/company_redirect',            to: 'sessions#company_redirect'
  get   '/set_snapshot',                to: 'temp#change_snapshot'
  get   '/change_company',              to: 'sessions#company_redirect'
  get   '/v2/backend',                  to: 'backend_v_two#load_csv'
  get   '/backend',                     to: 'utils#backend'
  post  '/upload_csv',                  to: 'utils#upload_csv_v2'
  post  '/upload_excel',                to: 'utils#upload_excel'
  get   '/qqq',                         to: 'utils#qqq'

  get   '/get_networks_per_company',    to: 'backend_v_two#get_networks_per_company'

  post  '/upload_network_csv_v2',       to: 'backend_v_two#upload_network_csv_v2'
  get   '/get_filters_values',          to: 'utils#list_filters'
  get   '/get_colors',                  to: 'utils#list_colors'
  get   '/admin_page',                  to: 'backoffice#admin_page'
  get   '/get_employees',               to: 'employees#list_employees'
  get   '/get_managers',                to: 'employees#list_managers'
  get   '/get_formal_structure',        to: 'groups#formal_structure'
  get   '/get_groups',                  to: 'groups#groups'
  get   '/get_snapshots',               to: 'snapshots#list_snapshots'
  get   '/domains_list',                to: 'backoffice#domains_list'

  get   '/get_questionnaires',             to: 'mobile/questionnaire#get_questionnaires_for_settings_tab'
  get   '/get_questionnaire_participants', to: 'mobile/questionnaire#get_questionnaire_participants'

  get     'request_google_access', to: 'clients#request_google_access'
  get     'accept_google_access',  to: 'clients#accept_google_access'

  # API

  post    '/API/signin',                to: 'sessions#api_signin'
  get     '/API/signout',               to: 'sessions#destroy'
  get     '/API/get_snapshot',          to: 'email_snapshot_data#network_snapshot'
  get     '/API/get_advice_measure',    to: 'email_snapshot_data#advice_measure'
  post    '/API/import_emails',         to: 'raw_data_entries#import_emails'
  post    '/API/next_task',             to: 'clients#next_task'
  post    '/API/sync_config',           to: 'clients#sync_config'
  post    '/API/task_done',             to: 'clients#task_done'
  post    '/API/get_protocol',          to: 'clients#protocol_as_yaml_file'
  post    '/API/upload_log',            to: 'clients#upload_log'
  post    '/API/export_to_csv',         to: 'clients#export_to_csv'
  post    '/API/init_report_xls',       to: 'utils#init_report_xls'
  get     '/API/export_xls',            to: 'utils#export_xls'
  get     '/API/download_interact',     to: 'utils#download_interact_report'
  get     '/v2/API/download_gen_report',to: 'utils#download_generic_report'
  get     '/API/create_and_download_report_xls', to: 'utils#create_and_download_report_xls'
  post    '/API/collect_error_lines',   to: 'clients#collect_error_lines'
  post    '/API/import_meetings',       to: 'raw_meetings_data#import_meetings'

  get     '/API/get_pins',              to: 'pins#show'
  post    '/API/delete_pins',           to: 'pins#delete'
  post    '/API/newpin',                to: 'pins#new'
  post    '/API/rename',                to: 'pins#rename'
  post    '/create_preset',             to: 'pins#new'

  get     '/API/get_measure_data',      to: 'measures#show'
  get     '/API/get_flag_data',         to: 'measures#show_flag'
  get     '/API/get_analyze_data',      to: 'measures#show_analyze'
  get     '/API/get_snapshot_list',     to: 'measures#show_snapshot_list'
  get     '/API/get_directory_data',    to: 'measures#show_directory'
  get     '/API/get_employee_measures', to: 'measures#show_employee_measures'
  get     '/API/get_external_data',     to: 'measures#show_3rd_line_data'
  get     '/API/get_group_measures',    to: 'measures#show_group_measures'
  get     '/API/get_filters',           to: 'pins#filters'
  get     '/API/get_employess_pin',     to: 'pins#show_preset_employess'
  get     '/API/get_play_session',      to: 'measures#show_play_session'

  get     '/API/get_company_statistics'     , to: 'company_statistics#get_company_statistics'
  get     'API/get_ui_levels'               , to: 'ui_level_configuration#get_ui_levels'
  get     'API/get_wordcloud'               , to: 'word_cloud#get_wordcloud'
  get     'API/tree_map'                    , to: 'dashboard#tree_map'
  get     'API/dyads_with_the_biggest_diff' , to: 'dashboard#dyads_with_the_biggest_diff'
  get     'API/communication_volume_changes_between_dyads', to:'dashboard#communication_volume_changes_between_dyads'
  get     '/API/get_overlay_snapshot_data',   to: 'overlay_snapshot_data#show'
  get     '/API/get_overlay_entity_group',    to: 'overlay_entity_group#show'
  get     '/API/get_keywords',                to: 'overlay_snapshot_data#show_keywords'
  get     '/get_overlay_entity_configuration', to: 'backend_v_two#fetch_overlay_entity_configuration'
  post    '/change_entity_configuration_status', to: 'backend_v_two#change_entity_configuration_status'
############################ CDS ###############################


  post    '/API/cds_show_network_and_metric_names',  to: 'measures#cds_network_dropdown_list'
  get     '/API/get_cds_flag_data',         to: 'measures#cds_show_flag'
  get     '/API/get_cds_gauge_data',        to: 'measures#cds_show_gauge'
  get     '/API/get_cds_measure_data',      to: 'measures#cds_show'
  get     '/API/cds_show_group_measures',   to: 'measures#cds_show_group_measures'
  get     '/API/cds_get_analyze_data',      to: 'measures#cds_show_analyze'
  get     '/API/cds_network_dropdown_list', to: 'measures#cds_network_dropdown_list'
  get     '/API/get_cds_flagged_employees', to: 'measures#cds_show_flagged_employees'

  get     '/API/get_emails_network',        to: 'network_snapshot_data#show_emails_network'
  post    '/API/add_email_relation',        to: 'network_snapshot_data#add_email_relation'
  post    '/API/delete_email_relation',     to: 'network_snapshot_data#delete_email_relation'

  post    'company/update',             to: 'companies#update'
  post    'company/diactivate',         to: 'companies#diactivate'
  post    'company/create',             to: 'companies#create'

  post    'setting/set_external_data',  to: 'settings#create_or_update_external_data'

  get     'setting/get_group_individual_state', to: 'utils#fetch_group_individual_state'
  post     'setting/save_group_individual_state', to: 'utils#save_group_individual_state'
  ############ algorithms tests ####
  get 'algorithms_test/company_reset',           to: 'backend_v_two#company_reset'
  get 'algorithms_test/company_structure_reset', to: 'backend_v_two#company_structure_reset'
  get 'algorithms_test/precalculate',            to: 'backend_v_two#precalculate'

  ############ mobile ###############

  get   '/mobile',          to: 'mobile/companies#show'
  get   '/questionnaire',   to: 'application#show_mobile'
  get    'get_questionnaire_employees' => 'mobile/employees#all_employees'
  post   'get_next_question' => 'mobile/questions#next'

  get    'company/show'   => 'mobile/companies#show'
  post   'company/update' => 'mobile/companies#update'
  post   'company/create' => 'mobile/companies#create'
  delete 'company/remove' => 'mobile/companies#remove'

  get   'select_company', to: 'mobile/companies#select'

  post  'employee/create' => 'mobile/employees#create'
  post  'employee/update' => 'mobile/employees#update'
  post  'employee/remove' => 'mobile/employees#remove'

  post  'question/create' => 'mobile/questions#create'
  post  'question/remove' => 'mobile/questions#remove'

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
end
