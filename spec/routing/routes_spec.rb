require 'spec_helper'

describe 'Routes', type: :routing do
  describe 'as user' do
    it 'route signin to sessions_controller/new' do
      expect(get: '/signin').to route_to(
        controller: 'sessions',
        action: 'signin'
      )
    end

    it 'route signout to sessions_controller/destroy' do
      expect(get: '/signout').to route_to(
        controller: 'sessions',
        action: 'destroy'
      )
    end

    it 'route get_employees_by_company_id to employees_controller/get_employees_by_company_id' do
      expect(get: '/get_employees').to route_to(
        controller: 'employees',
        action: 'list_employees'
      )
    end

    it 'route formal_structure_by_company_id to groups_controller/formal_structure_by_company_id' do
      expect(get: '/get_formal_structure').to route_to(
        controller: 'groups',
        action: 'formal_structure'
      )
    end

    it 'route get_groups_by_company_id to groups_controller/get_groups_by_company_id' do
      expect(get: '/get_groups').to route_to(
        controller: 'groups',
        action: 'groups'
      )
    end

    it 'route get_snapshot_by_company_id to network_nodes_controller/list_snapshots_by_company_id' do
      expect(get: '/get_snapshots').to route_to(
        controller: 'snapshots',
        action: 'list_snapshots'
      )
    end

    it 'route /API/get_directory_data to measures/' do
      expect(get: '/API/get_directory_data').to route_to(
        controller: 'measures',
        action: 'show_directory'
      )
    end

    it 'route /API/get_snapshot_list to measures/' do
      expect(get: '/API/get_snapshot_list').to route_to(
        controller: 'measures',
        action: 'show_snapshot_list'
      )
    end
    it 'route /API/get_external_data' do
      expect(get: '/API/get_external_data').to route_to(
        controller: 'measures',
        action: 'show_3rd_line_data'
      )
    end

    it 'route setting/set_external_data' do
      expect(post: 'setting/set_external_data').to route_to(
        controller: 'settings',
        action: 'create_or_update_external_data'
      )
    end
    it 'route request_google_access to clients/request_google_access' do
      expect(get: 'request_google_access').to route_to(
        controller: 'clients',
        action: 'request_google_access'
      )
    end
    it 'route accept_google_access to clients/accept_google_access' do
      expect(get: 'accept_google_access').to route_to(
        controller: 'clients',
        action: 'accept_google_access'
      )
    end
    it 'route /API/get_play_session' do
      expect(get: '/API/get_play_session').to route_to(
        controller: 'measures',
        action: 'show_play_session'
      )
    end
    it 'route /API/get_play_session' do
      expect(get: '/API/get_employess_pin').to route_to(
        controller: 'pins',
        action: 'show_preset_employess'
      )
    end
  end

  ######################## API ########################

  describe 'as API,' do
    it 'route signin to sessions_controller/api_signin' do
      expect(post: '/API/signin').to route_to(
        controller: 'sessions',
        action: 'api_signin'
      )
    end

    it 'route signout to sessions_controller/destroy' do
      expect(get: '/API/signout').to route_to(
        controller: 'sessions',
        action: 'destroy'
      )
    end

    it 'route next_job to clients/next_task' do
      expect(post: '/API/next_task').to route_to(
        controller: 'clients',
        action: 'next_task'
      )
    end

    it 'route job_done to clients/task_done' do
      expect(post: '/API/task_done').to route_to(
        controller: 'clients',
        action: 'task_done'
      )
    end
    it 'route sync_config to clients/sync_config' do
      expect(post: '/API/sync_config').to route_to(
        controller: 'clients',
        action: 'sync_config'
      )
    end
    it 'route upload_log to clients/upload_log' do
      expect(post: '/API/upload_log').to route_to(
        controller: 'clients',
        action: 'upload_log'
      )
    end
  end
end
