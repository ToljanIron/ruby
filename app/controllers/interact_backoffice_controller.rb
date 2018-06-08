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
    @showErrors = 'none'
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

  def get_questionnaires
    authorize :application, :passthrough
    ibo_process_request do
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, nil]
    end
  end

  def questionnaire_create
    authorize :application, :passthrough
    ibo_process_request do
      err = InteractBackofficeActionsHelper.create_new_questionnaire(@cid)
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, err]
    end
  end

  def questionnaire_delete
    authorize :application, :passthrough
    ibo_process_request do
      qid = params['qid']
      err = Questionnaire.find(qid).delete
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, err]
    end
  end

  def questionnaire_update
    authorize :application, :passthrough
    ibo_process_request do
      aq = update_questionnaire_properties
      quests = Questionnaire.get_all_questionnaires(@cid)
      [{quests: quests, activeQuest: aq}, nil]
    end
  end

  def update_questionnaire_properties
    quest = params['questionnaire']
    aq = Questionnaire.find(quest['id'])

    questState = aq.state == 'created' ? 'delivery_method_ready' : aq.state

    name = quest['name']
    deliveryMethod = quest['delivery_method']
    smsText = quest['sms_text']
    emailText = quest['email_text']
    emailSubject = quest['email_subject']

    language_id = quest['language_id']

    aq.update!(
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

    aq
  end

  ####################### Test  #######################


  def ttttttttttttttttest
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

  def create_new_test(aq)
    InteractBackofficeHelper.format_questionnaire_state(aq.state)
    testUserUrl = QuestionnaireParticipant
                    .where(questionnaire_id: aq.id)
                    .where(employee_id: -1)
                    .last
                    .create_link
    return testUserUrl
  end

  def questionnaire_run
    authorize :application, :passthrough

    ibo_process_request do
      qid = params[:qid]
      aq = Questionnaire.find(qid)
      InteractBackofficeActionsHelper.run_questionnaire(aq)
      [nil, nil]
    end
  end

  def update_test_participant
    authorize :application, :passthrough

    ibo_process_request do
      quest = params[:questionnaire]
      qid           = quest[:id]
      testUserName  = quest[:test_user_name]
      testUserEmail = quest[:test_user_email]
      testUserPhone = quest[:test_user_phone]

      aq = Questionnaire.find(qid)
      aq.update!(
        test_user_name: testUserName,
        test_user_email: testUserEmail,
        test_user_phone: testUserPhone
      )

      testUserUrl = create_new_test(aq)
      [{questionnaire: aq, test_user_url: testUserUrl}, nil]
    end
  end

  #################### Question #######################
  def get_questions
    authorize :application, :passthrough
    ibo_process_request do

      qid = params['qid']

      questions =
        QuestionnaireQuestion
          .where(questionnaire_id: qid)
          .joins("join network_names as nn on nn.id = questionnaire_questions.network_id")
          .order(:order)

      [{questions: questions}, nil]
    end
  end

  def questions_reorder
    authorize :application, :passthrough
    ibo_process_request do
      questions = params[:questions]
      questions.each do |q|
        qq = QuestionnaireQuestion.find(q['qid'])
        qq.update!(order: q['order'])
      end
      [{}, nil]
    end
  end
  def question_update
    authorize :application, :passthrough
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]

      qid = question['id']
      title = question['title']
      body = question['body']
      min = question['min']
      max = question['max']
      active = question['active']

      qq = QuestionnaireQuestion.find(qid)
      qq.update!(
        title: title,
        body: body,
        min: min,
        max: max,
        active: active
      )

      aq = qq.questionnaire
      if active && !participants_tab_enabled(aq)
        aq.update!(state: :questions_ready)
      end

      [{questionnaire: aq}, nil]
    end
  end

  def question_delete
    authorize :application, :passthrough
    ibo_process_request do
      id = params['qid']
      qq = QuestionnaireQuestion.find(id)
      qq.network_name.delete
      qq.delete
      questions =
        QuestionnaireQuestion
          .where(questionnaire_id: qq.questionnaire_id)
          .joins("join network_names as nn on nn.id = questionnaire_questions.network_id")
          .order(:order)

      [{questions: questions}, nil]
    end
  end

  def question_create
    authorize :application, :passthrough
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]

      title = question['title']
      body = question['body']
      min = question['min']
      max = question['max']
      active = question['active']
      order = params['order']

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
        order: order,
        active: active
      )
      ['ok', nil]
    end
  end

  ################# Participants #######################

  def participants
    authorize :application, :passthrough
    ibo_process_request do
      qid = params['qid']
     ret, errors = prepare_data(qid)
     [ret, errors]
    end
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

  def prepare_data(qid)

    qps =
      Employee
        .select("qp.id as pid, e.id as eid, e.first_name, e.last_name, e.external_id, e.img_url,
                 g.name as group_name, qp.status as status, ro.name as role, rank_id as rank ,
                 o.name as office, e.gender, jt.name as job_title, e.phone_number, e.email,
                 qp.active")
        .from("employees as e")
        .joins("left join groups as g on g.id = e.group_id and g.snapshot_id = e.snapshot_id")
        .joins("left join roles as ro on ro.id = e.role_id")
        .joins("left join offices as o on o.id = e.office_id")
        .joins("left join job_titles as jt on jt.id = e.job_title_id")
        .joins("join questionnaires as quest on quest.snapshot_id = e.snapshot_id")
        .joins("join questionnaire_participants as qp on qp.employee_id = e.id and qp.questionnaire_id = quest.id")
        .where("e.company_id = #{@cid}")
        .where("quest.id = ?", qid)
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

    ret = []
    errors = nil
    qps.each do |qp|
      begin
        status = InteractBackofficeHelper.resolve_status_name(qp['status'])
        active = (qp['active'].nil? ? false : qp['active'])
        ret << {
          pid: qp['pid'],
          eid: qp['eid'],
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
        errmsg = "Error loading employee: #{qp['emp_id']}: #{e.message}"
        errors = [] if errors.nil?
        errors << errmsg
      end
    end
    return [ret, errors]
  end

  def participants_update
    authorize :application, :passthrough
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      qid = par[:questionnaire_id]
      InteractBackofficeHelper.update_employee(@cid, par, qid)
      participants, errors = prepare_data(qid)
      aq = Questionnaire.find(qid)
      if !test_tab_enabled(aq)
        aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participants_create
    authorize :application, :passthrough
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      qid = par[:questionnaire_id]
      aq = Questionnaire.find(qid)
      InteractBackofficeHelper.create_employee(@cid, par, aq)
      participants, errors = prepare_data(qid)
      if !test_tab_enabled(aq)
        aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participants_delete
    authorize :application, :passthrough
    ibo_process_request do
      qpid = params[:qpid]
      qp = QuestionnaireParticipant.find(qpid)
      Employee.find(qp.employee_id).delete
      qp.try(:question_replies).try(:delete)
      qp.try(:delete)

      participants, errors = prepare_data(qp.questionnaire_id)
      [{participants: participants}, errors]
    end
  end

  def participant_resend
    authorize :application, :passthrough
    ibo_process_request do
      qpid = params[:qpid]
      qp = QuestionnaireParticipant.find(qpid)
      aq = qp.questionnaire
      if aq.state != 'sent'
        raise "Cant send messages to participants when questionnaire is not active"
      end
      InteractBackofficeActionsHelper.send_live_questionnaire(aq, qp)
      [{}, nil]
    end
  end

  def participant_reset
    authorize :application, :passthrough
    ibo_process_request do
      qpid = params[:qpid]
      qp = QuestionnaireParticipant.find(qpid)
      aq = qp.questionnaire
      if aq.state != 'sent'
        raise "Cant reset participant when questionnaire is not active"
      end
      qp.reset_questionnaire
      [{}, nil]
    end
  end

  def participants_get_emps
    authorize :application, :passthrough
    sid = Employee
      .where(company_id: @cid)
      .select(:snapshot_id)
      .distinct
      .pluck(:snapshot_id)
      .sort
      .last
    file_name = InteractBackofficeHelper.download_employees(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end


  def participants_bulk_actions
    authorize :application, :passthrough

    if !params['resend'].nil?
      InteractBackofficeActionsHelper.send_questionnaires(@aq)
      redirect_to '/interact_backoffice/participants'

    elsif !params['status'].nil?
      file_name = InteractBackofficeHelper.create_status_excel(@aq.id)
      send_file(
        "#{Rails.root}/tmp/#{file_name}",
        filename: file_name,
        type: 'application/vnd.ms-excel')
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

  def reports_summary
    authorize :application, :passthrough
    sid = params['sid']
    report_name = InteractBackofficeHelper.summary_report(sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  ################## Actions #########################################
  def img_upload
    authorize :application, :passthrough
    ibo_process_request do

      file = params[:file_name]
      file_name = file.original_filename
      empident = file_name[0..-5]

      qid = params[:qid]
      quest = Questionnaire.find(qid)
      sid = quest.snapshot_id

      emp = Employee.find_by(email: empident, snapshot_id: sid)
      emp = Employee.find_by(phone_number: empident, snapshot_id: sid) if emp.nil?
      err = []
      if emp.nil?
        err << "No participant with email or phone: #{empident}"
      else
        eid = emp.id
        err << InteractBackofficeActionsHelper.upload_employee_img(file, eid)
        ret, err2 = prepare_data(qid)
        err.concat(err2) if !err2.nil?
      end
      [ret, err]
    end
  end

  def download_sample
    authorize :application, :passthrough
    file_name = InteractBackofficeHelper.create_example_excel
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end

  ## Load employees from excel
  def upload_participants
    authorize :application, :passthrough
    puts "UPLOAING PART'S ........................"

    ibo_process_request do
      emps_excel = params[:fileToUpload]
      qid = params[:qid]
      aq = Questionnaire.find(qid)
      errors1 = ['No excel file uploaded']
      if !emps_excel.nil?
        sid = aq.snapshot_id
        puts "sid: #{sid}"
        eids, errors2 = load_excel_sheet(@cid, params[:fileToUpload], sid, true)
        InteractBackofficeHelper.add_all_employees_as_participants(eids, aq)

        ## Update the questinnaire's state if needed
        if !test_tab_enabled(aq)
          if QuestionnaireParticipant.where(questionnaire_id: aq.id).count > 1
            aq.update!(state: :notstarted)
          end
        end
      end

      ret, errors3 = prepare_data(qid)
      errors = []
      errors << errors1 unless errors1
      errors << errors2 unless errors2
      errors << errors3 unless errors3
      [ret, errors: errors ]
    end
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

  def ibo_process_request
    res = nil
    err = nil
    action = params['action']
    begin
      ActiveRecord::Base.transaction do
        res, err = yield
      end
    rescue => e
      msg = "Error in action - #{action}: #{e.message}"
      puts msg
      puts e.backtrace.join("\n")
      EventLog.log_event(event_type_name: 'ERROR', message: msg)
      err = ["Error: #{msg}"]
    end
    render json: Oj.dump({data: res, err: err}), status: 200
  end
end
