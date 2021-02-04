require 'oj'
require 'oj_mimic_json'

class InteractBackofficeController < ApplicationController
  include InteractBackofficeHelper
  include ImportDataHelper
  include SimulatorHelper

  before_action :before_interact_backoffice

  #################### Questionnaire #######################
  def before_interact_backoffice
    @cid = current_user.company_id
    @company_name = Company.find(@cid).name
    @user_name = "#{current_user.first_name} #{current_user.last_name}"
    @showErrors = 'none'
  end

  def questionnaire
    authorize :interact, :authorized?

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
    authorize :interact, :authorized?
    ibo_process_request do
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, nil]
    end
  end

  def questionnaire_create
    authorize :interact, :authorized?
    ibo_process_request do
      err = InteractBackofficeActionsHelper.create_new_questionnaire(@cid)
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, err]
    end
  end

  def questionnaire_delete
    authorize :interact, :authorized?
    ibo_process_request do
      qid = sanitize_id(params['qid'])
      err = Questionnaire.find(qid).delete
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, err]
    end
  end

  def questionnaire_update
    authorize :interact, :authorized?
    ibo_process_request do
      aq = update_questionnaire_properties
      quests = Questionnaire.get_all_questionnaires(@cid)
      [{quests: quests, activeQuest: aq}, nil]
    end
  end
  
  def remove_participants
    authorize :interact, :authorized?
    ibo_process_request do
      qid = params[:qid]
      q = Questionnaire.find(qid)
      errors = InteractBackofficeActionsHelper.remove_questionnaire_participans(qid)
      [{participants: [], questionnaire: q}, errors: [] ]
    end
  end

  def questionnaire_copy
    authorize :interact, :authorized?
    ibo_process_request do

      qid = sanitize_id(params['qid'])
      rerun = sanitize_boolean(params['rerun'])

      err = InteractBackofficeActionsHelper.create_new_questionnaire(@cid, qid, rerun)
      quests = Questionnaire.get_all_questionnaires(@cid)
      [quests, err]
    end
  end

  def update_questionnaire_properties
    quest = params['questionnaire']
    aq = Questionnaire.find( sanitize_id(quest['id']))

    questState = aq.state == 'created' ? 'delivery_method_ready' : aq.state
    questState = sanitize_alphanumeric(questState)
    deliveryMethod = quest['delivery_method']

    # Do not sanitize these texts because they can contain anything.
    # Expecting update! to take care of that
    name =         quest['name']
    smsText =      quest['sms_text']
    emailText =    quest['email_text']
    emailSubject = quest['email_subject']

    language_id = sanitize_id(quest['language_id'])

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
    authorize :interact, :authorized?

    ibo_process_request do
      qid = sanitize_id(params[:qid])
      aq = Questionnaire.find(qid)
      InteractBackofficeActionsHelper.run_questionnaire(aq)
      res_aq = Questionnaire.find(qid).as_json
      res_aq['state'] = Questionnaire.state_name_to_number(aq['state'])

      [{questionnaire: res_aq}, nil]
    end
  end

  def questionnaire_close
    authorize :interact, :authorized?

    ibo_process_request do
      p = params.permit(:qid)
      qid = sanitize_id(p[:qid])
      aq = Questionnaire.find(qid)
      InteractBackofficeActionsHelper.close_questionnaire(aq)
      res_aq = Questionnaire.find(qid).as_json
      res_aq['state'] = Questionnaire.state_name_to_number(aq['state'])

      [{questionnaire: res_aq}, nil]
    end
  end

  def update_test_participant
    authorize :interact, :authorized?

    ibo_process_request do
      quest = params[:questionnaire]
      qid           = sanitize_id(quest[:id])
      testUserName  = sanitize_alphanumeric_with_space(quest[:test_user_name])
      testUserEmail = sanitize_alphanumeric(quest[:test_user_email])
      testUserPhone = sanitize_alphanumeric(quest[:test_user_phone])

      aq = Questionnaire.find(qid)
      aq.update!(
        test_user_name: testUserName,
        test_user_email: testUserEmail,
        test_user_phone: testUserPhone
      )
      aq.update!(state: :ready) if !InteractBackofficeHelper.test_tab_enabled(aq)

      InteractBackofficeActionsHelper.send_test_questionnaire(aq)
      testUserUrl = create_new_test(aq)
      aq = aq.as_json
      aq['state'] = Questionnaire.state_name_to_number(aq['state'])
      [{questionnaire: aq, test_user_url: testUserUrl}, nil]
    end
  end

  #################### Question #######################
  def get_questions
    authorize :interact, :authorized?
    ibo_process_request do

      qid = sanitize_id(params['qid'])

      questions =
        QuestionnaireQuestion
          .where(questionnaire_id: qid)
          .joins("join network_names as nn on nn.id = questionnaire_questions.network_id")
          .order(is_funnel_question: :desc, active: :desc, order: :asc)

      [{questions: questions}, nil]
    end
  end

  def questions_reorder
    authorize :interact, :authorized?
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
    authorize :interact, :authorized?
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]

      qid = sanitize_id(question['id'])
      title = question['title']
      body = question['body']
      min = sanitize_number(question['min'])
      max = sanitize_number(question['max'])
      active = sanitize_boolean(question['active'])

      qq = QuestionnaireQuestion.find(qid)
      qq.update!(
        title: title,
        body: body,
        min: min,
        max: max,
        active: active
      )

      if (qq.is_funnel_question)
        InteractBackofficeHelper.update_depends_on(qq.questionnaire_id, qq.id, active)
      elsif qq.active
        f_q = QuestionnaireQuestion.where(questionnaire_id: qq.questionnaire_id, active: true, is_funnel_question: true)
        if f_q
          qq.update!(depends_on_question: f_q.first.id)
        end
      end

      aq = qq.questionnaire
      aq.update!(state: :questions_ready) if !participants_tab_enabled(aq)
      aq = aq.as_json
      aq['state'] = Questionnaire.state_name_to_number(aq['state'])

      [{questionnaire: aq}, nil]
    end
  end

  def question_delete
    authorize :interact, :authorized?
    ibo_process_request do
      id = sanitize_id(params['qid'])
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
    authorize :interact, :authorized?
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]
      qid = params[:qid]
      cid = Questionnaire.find(qid).try(:company_id)

      if (cid != @cid)
        raise "Not allowed"
      end

      sanitize_id(question['id'])
      question['title']
      question['body']
      sanitize_number(question['min'])
      sanitize_number(question['max'])
      sanitize_boolean(question['active'])

      order = sanitize_number(params['order'])
      if (order.nil?)
        order = question['order']
      end

      InteractBackofficeHelper.create_new_question(@cid, qid, question, order)
      ['ok', nil]
    end
  end

  ################# Participants #######################

  def participants
    authorize :interact, :authorized?
    ibo_process_request do
      qid =        sanitize_id(params['qid'])
      page =       sanitize_number(params['page'])
      searchText = sanitize_alphanumeric(params['searchText'])
     ret, errors = prepare_data(qid, page, searchText)
     [ret, errors]
    end
  end

  ##
  ## Return details about a particpant's progress in the qustionnaire
  ##
  def participant_status
    authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params['qpid'])

      qp = QuestionnaireParticipant.find(qpid)
      quest_url = qp.create_link
      current_question = qp.current_questiannair_question_id
      emp = qp.employee
      name = "#{emp.first_name} #{emp.last_name}"
      qid = qp.questionnaire_id

      sqlstr = "
      SELECT qq.title, qq.order, qq.id AS questionnaire_question_id,
        (
          SELECT count(*)
          FROM question_replies as qr
          WHERE
            qr.questionnaire_question_id = qq.id AND
            qr.questionnaire_participant_id = #{qpid}
        ) AS count
      FROM questionnaire_questions as qq
      WHERE qq.active = true AND questionnaire_id = #{qp.questionnaire_id}
      ORDER BY qq.order"

      questions = ActiveRecord::Base.connection.exec_query(sqlstr).to_hash

      ## If there is a funnel question then the number of particpants per question
      ## is it the number the particpant has selected.
      ## otherwise it's the number of participants in the questionnaire
      funnel_question = QuestionnaireQuestion
        .where(questionnaire_id: qid, active: true, order: 0).last
      qps_per_question = QuestionnaireParticipant
        .where(questionnaire_id: qid).count - 1
      if !funnel_question.nil?
        qps_per_question = QuestionReply
          .where(questionnaire_question_id: funnel_question.id,
                 questionnaire_participant_id: qpid)
          .where.not(answer: nil)
          .count
      end

      ret = {
        participantId: qpid,
        qps_per_question: qps_per_question,
        questionnaireUrl: quest_url,
        currentQuestionId: current_question,
        name: name,
        questions: questions,
        status: QuestionnaireParticipant.translate_status(qp.status)
      }

     [ret, nil]
    end
  end

  def participants_filter
    authorize :interact, :authorized?
    @active_nav = 'participants'
    errors = params[:errors]

    @sort_field_name, @sort_dir, sort_clicked =
                        InteractBackofficeHelper.get_sort_field(params)

    if !params[:filter].nil? || sort_clicked
      ## Filters
      @filter_first_name = sanitize_alphanumeric_with_space(params[:filter_first_name])
      @filter_last_name =  sanitize_alphanumeric_with_space(params[:filter_last_name])
      @filter_email =      sanitize_alphanumeric(params[:filter_email])
      @filter_status =     params[:filter_status]
      @filter_phone =      sanitize_alphanumeric(params[:filter_phone])
      @filter_group =      sanitize_alphanumeric_with_space(params[:filter_group])
      @filter_office =     sanitize_alphanumeric_with_space(params[:filter_office])
      @filter_role =       sanitize_alphanumeric_with_space(params[:filter_role])
      @filter_rank =       sanitize_number(params[:filter_rank])
      @filter_job_title =  sanitize_alphanumeric_with_space(params[:filter_job_title])
      @filter_gender =     sanitize_number(params[:filter_gender])
      @filter_in_survey =  params[:filter_in_survey]

      prepare_data(errors)
      render 'participants'
    else

      redirect_to '/interact_backoffice/participants'
    end

  end

  def prepare_data(qid, page = 0, searchText = nil)

    searchCond = nil
    if !searchText.nil?
      searchText.sanitize_is_string_with_space
      searchCond = "first_name like '%#{searchText}%' "
      searchCond += "OR last_name like '%#{searchText}%' "
      searchCond += "OR email like '%#{searchText}%' "
      searchCond += "OR phone_number like '%#{searchText}%' "
      searchCond += "OR g.name like '%#{searchText}%' "
      searchCond += "OR o.name like '%#{searchText}%' "
      searchCond += "OR ro.name like '%#{searchText}%' "
      searchCond += "OR jt.name like '%#{searchText}%'"
    end

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
        .where(searchCond.nil? ? '1 = 1' : searchCond)
        .order("#{@sort_field_name} #{@sort_dir}")
        .limit(20)
        .offset(page)

    ret = []
    errors = nil
    qps.each do |qp|
      begin
        status = InteractBackofficeHelper.resolve_status_name(qp['status'])
        active = (qp['active'].nil? ? false : qp['active'])
        ret << {
          pid: qp['pid'],
          eid: qp['eid'],
          first_name: sanitize( qp['first_name'] ),
          last_name: sanitize( qp['last_name'] ),
          external_id: sanitize( qp['external_id'] ),
          img_url: qp['img_url'],
          group_name: sanitize( qp['group_name'] ),
          status: status,
          role: sanitize( qp['role'] ),
          rank: qp['rank'],
          office: sanitize( qp['office'] ),
          gender: qp['gender'],
          job_title: sanitize( qp['job_title'] ),
          phone_number: sanitize( qp['phone_number'] ),
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
    authorize :interact, :authorized?
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      qid = sanitize_id(par[:questionnaire_id])
      InteractBackofficeHelper.update_employee(@cid, par, qid)
      participants, errors = prepare_data(qid)
      aq = Questionnaire.find(qid)
      if !InteractBackofficeHelper.test_tab_enabled(aq)
        aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participants_create
    authorize :interact, :authorized?
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      qid = sanitize_id(par[:questionnaire_id])
      aq = Questionnaire.find(qid)
      InteractBackofficeHelper.create_employee(@cid, par, aq)
      participants, errors = prepare_data(qid)
      if !InteractBackofficeHelper.test_tab_enabled(aq)
        aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participants_delete
    authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      aq = InteractBackofficeHelper.delete_participant(qpid)
      participants, errors = prepare_data(aq[:id])
      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participant_resend
    authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      aq = qp.questionnaire
      if aq.state != 'sent'
        raise "Cant send messages to participants when questionnaire is not active"
      end
      InteractBackofficeActionsHelper.send_live_questionnaire(aq, qp)
      [{}, nil]
    end
  end

  def close_participant_questionnaire
    authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      qp.update(status: 3)
      [{}, nil]
    end
  end

  def set_active_questionnaire_question
    authorize :interact, :authorized?
    ibo_process_request do
      qqid = sanitize_id(params[:qqid])
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      qp.update(current_questiannair_question_id: qqid)
      [{}, nil]
    end
  end

  def participant_reset
    authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      aq = qp.questionnaire
      # if aq.state != 'sent' && aq.state != 'ready' && aq.state != 'notstarted'
      #   raise "Cant reset participant when questionnaire is not active - it is #{aq.state}"
      # end
      qp.reset_questionnaire
      [{}, nil]
    end
  end

  def participants_get_emps
    authorize :interact, :authorized?
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
    authorize :interact, :authorized?

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
    authorize :interact, :authorized?
    @active_nav = 'reports'
  end

  def reports_network
    authorize :interact, :authorized?
    qid = sanitize_id(params['qid'])
    return nil if qid.nil?
    sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    return nil if sid.nil?
    report_name = InteractBackofficeHelper.network_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_bidirectional_network
    authorize :interact, :authorized?
    qid = sanitize_id(params['qid'])
    return nil if qid.nil?
    sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    return nil if sid.nil?
    report_name = InteractBackofficeHelper.bidirectional_network_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_measures
    authorize :interact, :authorized?
    qid = sanitize_id(params['qid'])
    return nil if qid.nil?
    sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    return nil if sid.nil?
    report_name = InteractBackofficeHelper.measures_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_summary
    authorize :interact, :authorized?
    sid = sanitize_id(params['sid'])
    report_name = InteractBackofficeHelper.summary_report(sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  ################## Actions #########################################
  def img_upload
    authorize :interact, :authorized?
    ibo_process_request do

      # file = sanitize_alphanumeric(params[:file_name])
      file = params[:file_name]
      file_name = file.original_filename
      empident = file_name[0..-5]

      qid = sanitize_id(params[:qid])
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
    authorize :interact, :authorized?
    file_name = InteractBackofficeHelper.create_example_excel
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end

  def download_participants_status
    authorize :interact, :authorized?
    qid = sanitize_id(params[:qid])
    file_name = InteractBackofficeHelper.create_status_excel(qid)
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end

  ## Load employees from excel
  def upload_participants
    authorize :interact, :authorized?

    ibo_process_request do
      emps_excel = params[:fileToUpload]
      qid = sanitize_id(params[:qid])
      aq = Questionnaire.find(qid)
      errors1 = ['No excel file uploaded']
      if !emps_excel.nil?
        sid = aq.snapshot_id
        eids, errors2 = load_excel_sheet(@cid, params[:fileToUpload], sid, true)
        InteractBackofficeHelper.add_all_employees_as_participants(eids, aq)

        ## Update the questinnaire's state if needed
        if !InteractBackofficeHelper.test_tab_enabled(aq)
          if QuestionnaireParticipant.where(questionnaire_id: aq.id).count > 1
            aq.update!(state: :notstarted)
          end
        end
      end

      aq = aq.as_json
      aq['state'] = Questionnaire.state_name_to_number(aq['state'])

      participants, errors3 = prepare_data(qid)
      errors = []
      errors << errors1 unless errors1
      errors << errors2 unless errors2
      errors << errors3 unless errors3
      [{participants: participants, questionnaire: aq}, errors: errors ]
    end
  end

  def simulate_results
    authorize :interact, :admin_only?
    ibo_process_request do
      qid = sanitize_id(params['qid'])
      sid = Questionnaire.find(qid).try(:snapshot_id)
      SimulatorHelper.simulate_questionnaire_replies(sid)
      ['ok', errors: nil ]
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
