include ImportDataHelper
include XlsHelper
include CdsUtilHelper
include Mobile::CompaniesHelper
include CreateSnapshotHelper
require './lib/tasks/modules/precalculate_metric_scores_for_custom_data_system_helper.rb'
include PrecalculateMetricScoresForCustomDataSystemHelper

class BackendVTwoController < ApplicationController
  def list_filters
    authorize :util, :index?
    company_id = current_user.company_id
    cid = Company.find(company_id).id
    res = {
      age_group: %w(15-24 25-34 35-44 45-54 55-64 65+),
      seniority: %w(0 1Y 2Y 3Y 4Y 5Y+),
      rank: %w(1 2 3 4 5 6),
      rank_2: %w(7 8 9 10 11 12),
      office: c.list_offices,
      job_title: Employee.job_title_by_company(cid),
      role_type: rolescope.pluck(:name),
      marital_status: MaritalStatus.all.pluck(:name),
      gender: Employee.genders.keys,
      direct_manager: Employee.direct_managers_by_company(cid),
      professional_manager: Employee.pro_managers_by_company(cid),
      friendship: %w(from to),
      collaboration: %w(from to),
      trust: %w(from to),
      expert: %w(from to),
      most_isolated: %w(from to),
      social_power: %w(from to),
      centrality: %w(from to),
      central: %w(from to),
      in_the_loop: %w(from to),
      politician: %w(from to)
    }
    render json: res, status: 200
  end

  def list_colors
    authorize :util, :index?
    company_id = current_user.company_id
    cache_key = "colors-company_id-#{company_id}"
    res = cache_read(cache_key)
    if res.nil?
      colors = init_colors
      colors = roles_colors(colors)
      colors = ranks_colors(colors)
      colors = office_colors(colors)

      res = {
        attributes: colors,
        manager_id: emp_colors,
        g_id: groups_colors
      }
      cache_write(cache_key, res)
    end

    render json: res, status: 200
  end

  def load_csv
    authorize :application, :admin?
    select_company_by_id(@current_user.company_id)
    get_networks_per_company
  end

  def fetch_overlay_entity_configuration
    authorize :application, :admin?
    fetched = OverlayEntityConfiguration.where(company_id: @current_user.company_id)
    types = OverlayEntityType.all
    if fetched.count < types.count
      types.each do |type|
        next if OverlayEntityConfiguration.find_by(company_id: @current_user.company_id, overlay_entity_type_id: type.id)
        OverlayEntityConfiguration.create(company_id: @current_user.company_id, overlay_entity_type_id: type.id, active: false)
      end
      fetched = OverlayEntityConfiguration.where(company_id: @current_user.company_id)
    end
    overlay_entity_configuration = fetched.map do |e|
      { id: e.id, name: e.overlay_entity_type.name, active: e.active }
    end
    render json: { overlay_entity_configuration: overlay_entity_configuration }
  end

  def change_entity_configuration_status
    authorize :application, :admin?
    new_conf = OverlayEntityConfiguration.find(params['overlay_entity_id'].to_i)
    new_conf.update_attribute(:active, params['activity']) if new_conf
    render json: { activity: new_conf.active }
  end

  def get_networks_per_company
    authorize :application, :passthrough
    company_id = current_user.company_id
    @network_names = NetworkName.where(company_id: company_id)
  end

  def upload_network_csv_v2
    authorize :application, :passthrough
    CdsUtilHelper.cache_delete_all
    errors = []
    company_id = current_user.company_id

    network             = NetworkName.find_by(id: params[:selected_network])
    use_latest_snapshot = params[:use_latest_snapshot] == '1' || false
    csv_file            = params[:csv_file]
    return redirect_to root_url + 'v2/backend' if !csv_file

    csv_type = (network.name == 'Communication Flow' ? 5 : 4)

    push_errors(errors, company_id, csv_file, network, csv_type, use_latest_snapshot)
    if errors.count > 0
      render json: errors.join("\n")
    else
      redirect_to backend_v2_path
    end
  end

  def company_reset
    authorize :application, :passthrough
    cid = params[:cid].nil? ? -1 : params[:cid].to_i
    sid = params[:sid].nil? ? Snapshot.last_snapshot_of_company(cid) : params[:sid].to_i
    ret = false || BackendVTwoHelper.company_reset(cid, sid)
    if ret
      render json: {status: "200"}
    else
      render json: {status: "500"}
    end
  end

  def company_structure_reset
    authorize :application, :passthrough
    cid = params[:cid].nil? ? -1 : params[:cid].to_i
    ret = false || BackendVTwoHelper.company_reset(cid,nil, true)
    if ret
      render json: {status: "200"}
    else
      render json: {status: "500"}
    end
  end


  ########################################################
  ##
  ## This api call assumes the follwoing that there are
  ## un-processed raw_data_entries for this company.
  ##
  ########################################################
  def precalculate
    authorize :application, :passthrough
    cid = current_user.company_id
    company = Company.find_by(id: cid)
    raise "Company not found for ID: #{cid}" if company.nil?

    snapshot = params[:snapshot]
    sid = nil
    if snapshot.nil?
      puts "Working on last snapshot"
      sid = Snapshot.last_snapshot_of_company(cid)
    else
      puts "In create_snapshot"
      sid = CreateSnapshotHelper.create_company_snapshot_by_weeks(cid, snapshot, true).id
    end

    gid = params[:gid].to_i || -1
    cmid = params[:cmid].to_i || -1
    aid = cmid != -1 ? CompanyMetric.find(cmid).algorithm_id : -1

    puts "Raking precalculate"
    PrecalculateMetricScoresForCustomDataSystemHelper::cds_calculate_scores(cid, gid, -1, aid, sid, true)
    puts "Done with precalculate"
    Rails.cache.clear
    render json: {status: "200"}
  end

  def init_report_xls
    authorize :util, :index?
    flash[:employee_data] = params[:employee_data]
    render json: { status: 'Report init done...' }
  end

  def export_xls
    authorize :util, :index?
    filename = params[:filename]
    send_file(Rails.root.join('tmp', "#{filename}"), encoding: 'utf8', type: 'application/vnd.ms-excel', disposition: 'attachment')
  end
end
