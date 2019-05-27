CompanyConfigurationTable.delete_all
Dotenv.load

## General parameters
CompanyConfigurationTable.find_or_create_by(key: 'display_field_in_questionnaire', comp_id: -1).update(value: 'role')
CompanyConfigurationTable.find_or_create_by(key: 'populate_questionnaire_automatically', comp_id: -1).update(value: 'true')
CompanyConfigurationTable.find_or_create_by(key: 'hide_employee_names', comp_id: -1).update(value: 'false')

## Collector parameters
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TYPE', comp_id: -1).update(value: 'Office365')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TYPE', comp_id: -1).update(value: 'Exchange')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_WRITE_TO_EVENT_LOG', comp_id: -1).update(value: 'true')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_LEVEL', comp_id: -1).update(value: 'info')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_DUMMY_COLLECTION_MODE', comp_id: -1).update(value: 'false')


#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_HOME', comp_id: -1).update(value: '/home/dev/Development/collector')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_FILES_PORTAL', comp_id: -1).update(value: '/home/dev/Development/collector/files_portal')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_HOME', comp_id: -1).update(value: '/var/collector')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_FILES_PORTAL', comp_id: -1).update(value: '/var/collector/files_portal')

CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_DIR', comp_id: -1).update(value: 'logs_dir')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_DONE_DIR', comp_id: -1).update(value: 'logs_dir/done')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_ERROR_DIR', comp_id: -1).update(value: 'logs_dir/error')

## Collector params related to FTP and Samba
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'Samba')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'FTP')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'SFTP')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_HOST', comp_id: -1).update(value: 'hostname')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_USER', comp_id: -1).update(value: 'username')
password = CdsUtilHelper.encrypt('password')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_PASSWORD', comp_id: -1).update(value: password)
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_SRC_DIR', comp_id: -1).update(value: '.')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_FILE_MASK', comp_id: -1).update(value: '*.log;*.gpg;*.zip;*.LOG')

## Collector office365 parameters
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_CLIENT_ID', comp_id: -1).update(value: '7f571d02-9714-4535-8517-e437b30c5150')
client_secret = ENV['OFFICE_365_CLIENT_SECRET']
encrypted_client_secret = CdsUtilHelper.encrypt(client_secret)
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_CLIENT_SECRET', comp_id: -1).update(value: encrypted_client_secret)
redirect_uri = ENV['OFFICE_365_REDIRECT_URI']
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_REDIRECT_URI', comp_id: -1).update(value: redirect_uri)
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_TOKEN_ENDPOINT', comp_id: -1).update(value: 'https://login.microsoftonline.com/tenant-id/oauth2/v2.0/token')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_TENANT_ID', comp_id: -1).update(value: '')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_WHITE_LIST_FILE', comp_id: -1).update(value: './collector/white_list.csv')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_SCOPE', comp_id: -1).update(value: 'https://graph.microsoft.com/.default')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_USERS_BASE_URL', comp_id: -1).update(value: 'https://graph.microsoft.com/v1.0/users')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_O365_REDIRECT_STATE', comp_id: -1).update(value: 'o7iWc60KWrbHKeWi')

## Log files unzip
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_UNZIP_TYPE', comp_id: -1).update(value: 'unzip')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_UNZIP_TYPE', comp_id: -1).update(value: '7z')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_UNZIP_TYPE', comp_id: -1).update(value: '7z+passphrase')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_UNZIP_TYPE', comp_id: -1).update(value: 'none')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_UNZIP_PASSPHRASE', comp_id: -1).update(value: 'passphrase')

## Log files decrypt
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_DECRYPTION_TYPE', comp_id: -1).update(value: 'gpg')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_DECRYPTION_TYPE', comp_id: -1).update(value: 'none')
passphrase2 = CdsUtilHelper.encrypt('password')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_DECRYPTION_PASSPHRASE', comp_id: -1).update(value: passphrase2)

## Collector parser
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_PARSER_TYPE', comp_id: -1).update(value: 'exchange')


## App params
CompanyConfigurationTable.find_or_create_by(key: 'INFO_LOG_LEVEL', comp_id: -1).update(value: 'info')
CompanyConfigurationTable.find_or_create_by(key: 'APP_SERVER_NAME', comp_id: -1).update(value: 'stepahead')
CompanyConfigurationTable.find_or_create_by(key: 'MIN_EMPS_IN_GROUP_FOR_ALGORITHMS', comp_id: -1).update(value: '2')
CompanyConfigurationTable.find_or_create_by(key: 'NTP_SERVER', comp_id: -1).update(value: 'time.windows.com')
CompanyConfigurationTable.find_or_create_by(key: 'process_meetings', comp_id: -1).update(value: 'true')

