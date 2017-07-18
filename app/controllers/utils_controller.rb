include ImportDataHelper
include XlsHelper
include CdsUtilHelper
require './app/helpers/mobile/companies_helper.rb'
include Mobile::CompaniesHelper

class UtilsController < ApplicationController
  def qqq
    authorize :util, :index?
    render json: {qqq: 'qqq'}, status: 200
  end

  def list_filters
    authorize :util, :index?
    company_id = current_user.company_id
    c = Company.find(company_id)
    res = {
      age_group: %w(15-24 25-34 35-44 45-54 55-64 65+),
      seniority: %w(0 1Y 2Y 3Y 4Y 5Y+),
      rank: %w(1 2 3 4 5 6),
      rank_2: %w(7 8 9 10 11 12),
      office: c.list_offices,
      job_title: Employee.job_title_by_company(c.id),
      role_type: rolescope.pluck(:name),
      marital_status: MaritalStatus.all.pluck(:name),
      gender: Employee.genders.keys,
      direct_manager: Employee.direct_managers_by_company(c.id),
      professional_manager: Employee.pro_managers_by_company(c.id),
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
    OverlayEntityType.preload(:overlay_entity_groups).all.each do |type|
      next unless OverlayEntityConfiguration.find_by(company_id: c.id, overlay_entity_type_id: type.id).try(:active?)
      fetched = ActiveRecord::Base.connection.select_all("select oeg.id, oeg.name, count(oe.id) as entities
                                                          from overlay_entity_groups as oeg
                                                          left join overlay_entities as oe on oeg.id = oe.overlay_entity_group_id
                                                          where oeg.company_id = #{c.id} and oeg.overlay_entity_type_id = #{type.id}
                                                          group by oeg.id, oeg.name
                                                          order by entities desc").to_json
      res[type[:name].to_sym] = JSON.parse(fetched).map { |r| "#{r['name']} (#{r['entities']})" } # DO NOT CHANGE THIS FORMAT
    end
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

  def backend
    authorize :application, :passthrough
    select_company_by_id(@current_user.company_id)
  end

  def upload_csv_v2
    CdsUtilHelper.cache_delete_all
    authorize :application, :passthrough
    errors = []
    cid = current_user.company_id
    employees =             params[:employees]
    company_structure =     params[:company_structure_new]
    managment_relations =   params[:managment_relations]
    date_format =           params[:date_format]
    images =                params[:images]

    push_errors(errors, cid, company_structure,  nil, ImportDataHelper::GROUPS_CSV) if company_structure
    push_errors(errors, cid, employees,          nil, ImportDataHelper::EMPLOYEES_CSV, false, date_format) if employees
    push_errors(errors, cid, managment_relations,nil, ImportDataHelper::MANAGMENT_RELATION_CSV) if managment_relations

    upload_images(cid, images) if images

    if errors.count > 0
      render json: errors.join("\n")
    else
      redirect_to backend_path
    end
  end

  def upload_excel
    CdsUtilHelper.cache_delete_all
    authorize :application, :passthrough
    errors = []
    cid = current_user.company_id
    errors = load_excel_sheet(cid, params[:spreadsheet])
    if errors.count > 0
      render json: errors.join("\n")
    else
      redirect_to backend_path
    end
  end

  def precalculate
    authorize :application, :passthrough
    `rake db:precalculate_metric_scores\[6,-1,-1,-1,-1,true\]`
    Rails.cache.clear
    redirect_to backend_path
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

  def create_and_download_report_xls
    authorize :util, :index?
    file_name = "employee_report_user#{current_user[:id]}_#{Time.now.to_f.to_s[11, 15]}.xls"
    workbook = create_file(file_name)

    center = workbook.add_format
    red = workbook.add_format
    red.set_color('red')
    green = workbook.add_format
    green.set_color('green')

    formats = { center: center, red: red, green: green }
    formats.values.each { |format| format.set_align('center') }

    p = flash[:employee_data]
    group_id = params[:group_id]
    group_id = -1 if group_id != -1 && Group.find(group_id).parent_group_id.nil?
    pin_id = params[:pin_id].to_i
    p.each do |flag|
      title = flag[:title]
      employee_ids = flag[:employee_ids]
      worksheet = workbook.add_worksheet(title)
      write_report_to_sheet(worksheet, employee_ids, group_id, pin_id, formats)
    end
    workbook.close
    send_file(Rails.root.join('tmp', "#{file_name}"), encoding: 'utf8', type: 'application/vnd.ms-excel', disposition: 'attachment') unless Rails.env.test?
    render json: { status: 'File generated..' } if Rails.env.test?
  end

  def download_interact_report
    authorize :util, :index?
    cid = current_user.company_id
    report = XlsHelper.export_employee_attributes(cid)
    send_data(report,
              filename: 'stepahed-report.csv',
              disposition: 'attachment',
              encoding: 'utf8',
              type: 'text/csv')
  end

  def download_generic_report
    authorize :util, :index?
    puts 'Uploading report.txt'
    report = File.read('report.txt')
    send_data(report,
              filename: 'report.txt',
              disposition: 'attachment',
              encoding: 'utf8',
              type: 'text/csv')
  end

  def fetch_group_individual_state
    authorize :util, :index?
    state = UserConfiguration.where(user_id: current_user.id, key: 'bottom_up_view').first.try(:value) || false
    render json: { state: state }
  end

  def save_group_individual_state
    authorize :util, :index?
    params[:state]
    new_state = UserConfiguration.find_or_create_by(user_id: current_user.id)
    success = new_state.update_attributes(key: 'bottom_up_view', value:  params[:state])
    state = new_state.value
    render json: { success: success, state: state }
  end

  private

  def groups_colors
    dbgroups = Employee.by_company(current_user.company_id)
    groups = {}
    default_color = Color.find(8)[:rgb]
    dbgroups.each do |g|
      groups[g.id.to_s] = g.color.nil? ? default_color : g.color.rgb
    end
    return groups
  end

  def emp_colors
    dbemps = Employee.by_company(current_user.company_id)
    emps = {}
    default_color = Color.find(3)[:rgb]
    dbemps.each do |emp|
      emps[emp.id.to_s] = emp.color.nil? ? default_color : emp.color.rgb
    end
    return emps
  end

  def roles_colors(colors)
    dbroles = rolescope.includes(:color)
    default_color = Color.find(9)[:rgb]
    dbroles.each do |role|
      colors[role.name] = role.color.nil? ? default_color : role.color.rgb
    end
    return colors
  end

  def office_colors(colors)
    dboffice = officescope.all
    new_colors = Color.pluck(:rgb).sample(dboffice.size)
    dboffice.each do |office|
      colors[office.name] = new_colors.sample
    end
    return colors
  end

  def ranks_colors(colors)
    dbranks = Rank.all.includes(:color)
    dbranks.each do |rank|
      colors[rank.name] = rank.color.rgb
    end
    return colors
  end

  def init_colors
    return {
      'male'   => '83ddd2',
      'female' => 'fe9a34',
      '15-24'  => '9ac4db',
      '25-34'  => 'ffce00',
      '35-44'  => '83ddd2',
      '45-54'  => 'd8b525',
      '55-64'  => '29abe2',
      '65+'    => '00a99d'
    }
  end

  def random_colors
    colors = %w(9ac4db ffce00 83ddd2 d8b525 29abe2 00a99d fe9a34 0071bc a6e538 f15a24 1f5d75 c12f02)
    return colors[rand(0..11)]
  end

  def rolescope
    return RolePolicy::Scope.new(current_user, Role).resolve
  end

  def officescope
    return RolePolicy::Scope.new(current_user, Office).resolve
  end
end
