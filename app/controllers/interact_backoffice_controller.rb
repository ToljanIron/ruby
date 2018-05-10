require 'oj'
require 'oj_mimic_json'

class InteractBackofficeController < ApplicationController
  include InteractBackofficeHelper
  include ImportDataHelper

  before_action :before_interact_backoffice

  #################### Questionnaire #######################
  def before_interact_backoffice
    @cid = current_user.company_id
    @company_name = Company.find(@cid).name
    @user_name = "#{current_user.first_name} #{current_user.last_name}"
    @aq = InteractBackofficeHelper.active_questionnaire(@cid)
    @showErrors = 'none'
  end

  def get_questionnaires
    authorize :application, :passthrough

    res = Questionnaire.get_all_questionnaires(@cid)
    render json: Oj.dump(res), status: 200
  end

  def questionnaire
    authorize :application, :passthrough

    @active_nav = 'questionnaire'

    if !@aq.nil?
      @quest_name = @aq.name
      prepare_questionnaire_data()
    end
  end

  def prepare_questionnaire_data(errors=nil)
    if !@aq.nil?

      @questName = @aq.name

      ## Questionnaire state
      @questState = InteractBackofficeHelper.format_questionnaire_state(@aq.state)

      ## Delivery Method (SMS or Email)
      @deliveryMethodSms   = @aq.delivery_method == 'sms'   ? 'checked' : ''
      @deliveryMethodEmail = @aq.delivery_method == 'email' ? 'checked' : ''
      @smsText = @aq.sms_text
      @emailText = @aq.email_text
      @emailSubject = @aq.email_subject

      ## Test user
      @test_questionnaire_button_disabled = @aq.is_questionnaire_test_ready? ? '' : 'disabled'
      @testUserName  = @aq.test_user_name
      @testUserPhone = @aq.test_user_phone
      @testUserEmail = @aq.test_user_email

      ## Language
      @languageId = @aq.language.id

      ## Hide names
      hide_names = CompanyConfigurationTable.hide_employee_names?(@cid)
      @hideNames = hide_names ? 'checked' : ''
    end

    @showErrors = errors.nil? ? 'none' : 'initial'
    @errorText = errors.nil? ? [] : errors
  end

  def questionnaire_create
    authorize :application, :passthrough

    InteractBackofficeActionsHelper.create_new_questionnaire(@cid)
    quests = Questionnaire.get_all_questionnaires(@cid)
    res = {quests: quests}
    render json: Oj.dump(res), status: 200
  end

  def questionnaire_delete
    authorize :application, :passthrough

    qid = params['qid']
    Questionnaire.find(qid).delete
    quests = Questionnaire.get_all_questionnaires(@cid)
    res = {quests: quests}
    render json: Oj.dump(res), status: 200
  end

  def questionnaire_update
    authorize :application, :passthrough

    update_questionnaire_properties
    render json: 'ok', status: 200
  end

  def update_questionnaire_properties
    quest = params['questionnaire']
    name = quest['name']

    questState = @aq.state == 'created' ? 'delivery_method_ready' : @aq.state

    deliveryMethod = quest['delivery_method']
    smsText = quest['sms_text']
    emailText = quest['email_text']
    emailSubject = quest['email_subject']

    language_id = quest['language_id']

    @aq.update!(
      name: name,
      state: questState,
      delivery_method: deliveryMethod,
      sms_text: smsText,
      email_text: emailText,
      email_subject: emailSubject,
      language_id: language_id
    )

    ret = CompanyConfigurationTable.where(comp_id: @cid, key: CompanyConfigurationTable::HIDE_EMPLOYEES).last
    if params['hideNames']
      if ret.nil?
        CompanyConfigurationTable.create!(
          key: CompanyConfigurationTable::HIDE_EMPLOYEES,
          value: 'true',
          comp_id: @cid)
      else
        ret.update!(value: 'true')
      end
    else
      ret.delete if !ret.nil?
    end

  end

  ####################### Test  #######################
  def test
    authorize :application, :passthrough

    @quest_name    = @aq.name
    @questState = InteractBackofficeHelper.format_questionnaire_state(@aq.state)
    @testUserName  = @aq.test_user_name
    @testUserEmail = @aq.test_user_email
    @testUserPhone = @aq.test_user_phone
    @testUserUrl   = QuestionnaireParticipant
                       .where(questionnaire_id: @aq.id)
                       .where(employee_id: -1)
                       .last
                       .create_link
  end

  def test_update
    authorize :application, :passthrough

    errors = ibo_error_handler do
      ActiveRecord::Base.transaction do
        if !params['test-questionnaire'].nil?
          InteractBackofficeActionsHelper.send_test_questionnaire(@aq)
        elsif !params['run'].nil?
          InteractBackofficeActionsHelper.run_questionnaire(@aq)
        elsif !params['close'].nil?
          InteractBackofficeActionsHelper.close_questionnaire(@aq)
        elsif !params['update'].nil?
          update_test_participant
        elsif !params['delete'].nil?
          Questionnaire.drop_questionnaire(@aq.id)
          cid = @current_user.company_id
          Company.find(cid).clean_company
          redirect_to '/'
          return
        else
          raise "Illegal action for test_update"
        end
      end
    end
    if !errors.nil?
      puts "Errors: #{errors}"
    end

    redirect_to '/interact_backoffice/test'
  end

  def update_test_participant
    testUserName = params['testUserName']
    testUserEmail = params['testUserEmail']
    testUserPhone = params['testUserPhone']

    @aq.update!(
      test_user_name: testUserName,
      test_user_email: testUserEmail,
      test_user_phone: testUserPhone
    )
  end

  #################### Question #######################
  def questions
    authorize :application, :passthrough

    @active_nav = 'questions'

    @questions =
      QuestionnaireQuestion
        .where(questionnaire_id: @aq.id)
        .joins("join network_names as nn on nn.id = questionnaire_questions.network_id")
        .order(:order)

    @networks =
      NetworkName
        .select(:id, :name)
        .where(company_id: @cid)
        .order(:id)
  end

  ## Each row is a form, and each form has 2 buttons, so here
  ## we check which one was clicked before taking the action.
  def questions_update
    authorize :application, :passthrough

    if !params['update'].nil?
      update_question
    elsif !params['delete'].nil?
      delete_question
    else
      raise "Unknown action"
    end

    redirect_to '/interact_backoffice/questions'
  end

  def update_question
    id = params['id']
    order = params['order']
    title = params['heading']
    body = params['body']
    min = params['min']
    max = params['max']
    active = params['active'].nil? ? false : true

    qq = QuestionnaireQuestion.find(id)
    qq.update!(
      title: title,
      body: body,
      min: min,
      max: max,
      order: order,
      active: active
    )

    if active && !participants_tab_enabled(@aq)
      @aq.update(state: :questions_ready)
    end

  end

  def delete_question
    id = params['id']
    qq = QuestionnaireQuestion.find(id)
    qq.network_name.delete
    qq.delete
  end

  def questions_create
    authorize :application, :passthrough

    order = params['order']
    title = params['heading']
    body = params['body']
    min = params['min']
    max = params['max']

    network = NetworkName.where(company_id: @cid, name: title).last
    if network.nil?
      network = NetworkName.create!(
        company_id: @cid,
        name: title
      )
    end

    QuestionnaireQuestion.create!(
      company_id: @cid,
      questionnaire_id: @aq.id,
      title: title,
      body: body,
      network_id: network.id,
      min: min,
      max: max,
      order: order
    )


    redirect_to '/interact_backoffice/questions'
  end

  ################# Participants #######################

  def participants
    authorize :application, :passthrough
    @active_nav = 'participants'
    errors = params[:errors]

    prepare_data(errors)
  end

  def participants_filter
    authorize :application, :passthrough
    @active_nav = 'participants'
    errors = params[:errors]

    @sort_field_name, @sort_dir, sort_clicked =
                        InteractBackofficeHelper.get_sort_field(params)

    if !params[:filter].nil? || sort_clicked
      ## Filters
      @filter_first_name = params[:filter_first_name]
      @filter_last_name = params[:filter_last_name]
      @filter_email = params[:filter_email]
      @filter_status = params[:filter_status]
      @filter_phone = params[:filter_phone]
      @filter_group = params[:filter_group]
      @filter_office = params[:filter_office]
      @filter_role = params[:filter_role]
      @filter_rank = params[:filter_rank]
      @filter_job_title = params[:filter_job_title]
      @filter_gender = params[:filter_gender]
      @filter_in_survey = params[:filter_in_survey]

      prepare_data(errors)
      render 'participants'
    else

      redirect_to '/interact_backoffice/participants'
    end

  end

  def prepare_data(errors = nil)

    qps =
      Employee
        .select("e.id as emp_id, e.first_name, e.last_name, e.external_id, e.img_url,
                 g.name as group_name, qp.status as status, ro.name as role, rank_id as rank ,
                 o.name as office, e.gender, jt.name as job_title, e.phone_number, e.email")
        .from("employees as e")
        .joins("left join groups as g on g.id = e.group_id")
        .joins("left join questionnaire_participants as qp on qp.employee_id = e.id")
        .joins("left join roles as ro on ro.id = e.role_id")
        .joins("left join offices as o on o.id = e.office_id")
        .joins("left join job_titles as jt on jt.id = e.job_title_id")
        .where("e.company_id = #{@cid}")
        .where("qp.questionnaire_id = ?", @aq.id)
        .add_filter('first_name', @filter_first_name)
        .add_filter('last_name', @filter_last_name)
        .add_filter('email', @filter_email)
        .add_filter('status', (@filter_status == -1 || @filter_status.nil?) ? -1 : @filter_status.to_i)
        .add_filter('phone_number', @filter_phone)
        .add_filter('g.name', @filter_group)
        .add_filter('o.name', @filter_office)
        .add_filter('ro.name', @filter_role)
        .add_filter('rank_id', (@filter_rank == '' || @filter_rank.nil?) ? -1 : @filter_rank.to_i)
        .add_filter('jt.name', @filter_job_title)
        .add_filter('gender', (@filter_gender == -1 || @filter_gender.nil?) ? '' : @filter_gender.to_i)
        .order("#{@sort_field_name} #{@sort_dir}")

    @qps = []
    qps.each do |qp|
      begin
        status = InteractBackofficeHelper.resolve_status_name(qp['status'])
        active = status == 'Not in' ? false : true
        @qps << {
          emp_id: qp['emp_id'],
          first_name: qp['first_name'],
          last_name: qp['last_name'],
          external_id: qp['external_id'],
          img_url: qp['img_url'],
          group_name: qp['group_name'],
          status: status,
          role: qp['role'],
          rank: qp['rank'],
          office: qp['office'],
          gender: qp['gender'],
          job_title: qp['job_title'],
          phone_number: qp['phone_number'],
          email: qp['email'],
          active: active
        }
      rescue => e
        raise "Error loading employee: #{qp['emp_id']}: #{e.message}"
      end
    end

    stats =
      QuestionnaireParticipant
        .where(questionnaire_id: @aq.id)
        .where.not(employee_id: -1)
        .group(:status)
        .count
    comp     = stats[3] ||= 0
    open     = stats[1] ||= 0
    start    = stats[2] ||= 0
    not_comp = stats[0] ||= 0
    @stats = {
      completed: comp,
      started: open + start,
      not_started: not_comp
    }

    @showErrors = errors.nil? ? 'none' : 'initial'
    @errorText = errors.nil? ? [] : errors
  end

  ## Each row is a form, and each form has 4 buttons, so here
  ## we check which one was clicked before taking the action.
  def participants_update
    authorize :application, :passthrough

    errors = ibo_error_handler do
      if !params['update'].nil?
        InteractBackofficeHelper.update_employee(@cid, params, @aq.id)
      elsif !params['delete'].nil?
        delete_participant
      elsif !params['send'].nil?
        send_questionnaire
      elsif !params['reset'].nil?
        reset_questionnaire
      else
        raise "Unknown action"
      end
    end

    prepare_data(errors)
    redirect_to(
      controller: :interact_backoffice,
      action: :participants,
      errors: errors
    )
  end

  def delete_participant
    eid = params['id']
    ActiveRecord::Base.transaction do
      Employee.find(eid).delete
      qp = QuestionnaireParticipant.where(
             questionnaire_id: @aq.id,
             employee_id: eid
           ).last
      qp.try(:question_replies).try(:delete)
      qp.try(:delete)
    end
  end

  def send_questionnaire
    if @aq.state != 'sent'
      raise "Cant send messages to participants when questionnaire is not active"
    end
    eid = params['id']
    qp = QuestionnaireParticipant.where(
           questionnaire_id: @aq.id,
           employee_id: eid
         ).last
    InteractBackofficeActionsHelper.send_live_questionnaire(@aq, qp)
  end

  def reset_questionnaire
    if @aq.state != 'sent'
      raise "Cant reset participant when questionnaire is not active"
    end
    eid = params['id']
    QuestionnaireParticipant.where(
           questionnaire_id: @aq.id,
           employee_id: eid
         ).last.reset_questionnaire
  end

  def participants_create
    authorize :application, :passthrough
    InteractBackofficeHelper.create_employee(@cid, @aq.id, params)
    redirect_to '/interact_backoffice/participants'
  end

  ## Load employees from excel
  def participants_load
    authorize :application, :passthrough
    @active_nav = 'participants'

    emps_excel = params[:employeesExcel]
    errors = ['No excel file uploaded']
    if !emps_excel.nil?
      errors = load_excel_sheet(@cid, params[:employeesExcel], true)
      InteractBackofficeHelper.add_all_employees_as_participants(@aq)

      ## Update the questinnaire's state if needed
      if !test_tab_enabled(@aq)
        if QuestionnaireParticipant.where(questionnaire_id: @aq.id).count > 1
          @aq.update!(state: :notstarted)
        end
      end
    end

    prepare_data(errors)
    redirect_to(
      controller: :interact_backoffice,
      action: :participants,
      errors: errors[0..2]
    )
  end

  def participants_bulk_actions
    authorize :application, :passthrough

    if !params['resend'].nil?
      InteractBackofficeActionsHelper.send_questionnaires(@aq)
      redirect_to '/interact_backoffice/participants'

    elsif !params['example'].nil?
      file_name = InteractBackofficeHelper.create_example_excel
      send_file(
        "#{Rails.root}/tmp/#{file_name}",
        filename: file_name,
        type: 'application/vnd.ms-excel')

    elsif !params['status'].nil?
      file_name = InteractBackofficeHelper.create_status_excel(@aq.id)
      send_file(
        "#{Rails.root}/tmp/#{file_name}",
        filename: file_name,
        type: 'application/vnd.ms-excel')

    elsif !params['filterCompleted'].nil?
      redirect_to '/interact_backoffice/participants'

    elsif !params['filterStarted'].nil?
      redirect_to '/interact_backoffice/participants'

    elsif !params['filterNotStated'].nil?
      redirect_to '/interact_backoffice/participants'
    end
  end

  ################# Reports #######################
  def reports
    authorize :application, :passthrough
    @active_nav = 'reports'
  end

  def reports_network
    authorize :application, :passthrough
    report_name = InteractBackofficeHelper.network_report(@cid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_bidirectional_network
    authorize :application, :passthrough
    report_name = InteractBackofficeHelper.bidirectional_network_report(@cid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_measures
    authorize :application, :passthrough
    report_name = InteractBackofficeHelper.measures_report(@cid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  ################## Some utilities ###################################

  def ibo_error_handler
    begin
      yield
    rescue => e
      puts "Error in questionnaire_update action: #{e.message}"
      puts e.backtrace.join("\n")
      EventLog.log_event(event_type_name: 'ERROR', message: e.message)
      return ["Error: #{e.message}"]
    end
    return nil
  end
end
