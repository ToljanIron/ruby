## General parameters
CompanyConfigurationTable.find_or_create_by(key: 'display_field_in_questionnaire', comp_id: -1).update(value: 'role')
CompanyConfigurationTable.find_or_create_by(key: 'populate_questionnaire_automatically', comp_id: -1).update(value: 'true')
CompanyConfigurationTable.find_or_create_by(key: 'hide_employee_names', comp_id: -1).update(value: 'false')

## Collector parameters
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_LEVEL', comp_id: -1).update(value: 'info')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_HOME', comp_id: -1).update(value: '/home/dev/Development/collector')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_FILES_PORTAL', comp_id: -1).update(value: '/home/dev/Development/collector/files_portal')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_DIR', comp_id: -1).update(value: 'log_dir')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_DONE_DIR', comp_id: -1).update(value: 'log_dir/done')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_LOG_FILES_ERROR_DIR', comp_id: -1).update(value: 'log_dir/error')

## Collector params related to FTP and Samba
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'Samba')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'FTP')
#CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_TYPE', comp_id: -1).update(value: 'SFTP')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_HOST', comp_id: -1).update(value: 'test.rebex.net')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_USER', comp_id: -1).update(value: 'demo')
password = CdsUtilHelper.encrypt('password')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_PASSWORD', comp_id: -1).update(value: password)
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_SRC_DIR', comp_id: -1).update(value: '.')
CompanyConfigurationTable.find_or_create_by(key: 'COLLECTOR_TRNAS_FILE_MASK', comp_id: -1).update(value: '*.log')

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
