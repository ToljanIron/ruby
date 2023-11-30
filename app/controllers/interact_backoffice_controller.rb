require 'oj'
require 'oj_mimic_json'

class InteractBackofficeController < ApplicationController
  include InteractBackofficeHelper
  include ImportDataHelper
  include SimulatorHelper
  include SessionsHelper

  before_action :before_interact_backoffice
  before_action :require_authoration, only: [:get_questions, :participants,:participant_status,
                :questionnaire_status,:participants_get_emps, :reports_network,:reports_bidirectional_network,
                :reports_measures, :reports_survey,:participants_refresh,:download_sample,:download_participants_status,
                :get_factors]
  before_action :require_admin_authoration, only: [:questionnaire_update, :remove_participants,:questionnaire_run,:questionnaire_close,:update_test_participant,
                :questions_reorder,:question_update,:question_delete,:question_create,:participants_update,:participants_create,:participants_delete,:participant_resend,
                :close_participant_questionnaire, :set_active_questionnaire_question,:participant_reset,:img_upload,:upload_participants,
                :update_data_mapping,:save_k_factor]
  
  #################### Questionnaire #######################
  def before_interact_backoffice
    qid = sanitize_id(params['qid'])
    company_id = sanitize_id(params[:company_id])
    @cid = InteractBackofficeHelper.get_user_company(current_user,company_id,qid)  #current_user.company_id
    
    @company_name = Company.find(@cid).name
    @user_name = "#{current_user.first_name} #{current_user.last_name}"
    @showErrors = 'none'
  end

  def require_admin_authoration
    # begin
      qid = sanitize_id(params['qid'])
      @aq =  Questionnaire.find(qid)
      authorize @aq, :admin?
    # rescue Exception => e
      # raise "Questionnaire: #{qid} - #{e.message}"
    # end
  end

  def require_authoration
    # begin
      qid = sanitize_id(params['qid'])
      if qid.to_i != -1 && !qid.nil?
        @aq =  Questionnaire.find(qid)
        authorize @aq, :viewer?
      else
        authorize :interact, :authorized?
      end
    # rescue Exception => e
      # raise "Questionnaire: #{qid} - #{e.message}"
    # end
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
    if current_user.super_admin?
      @cid = sanitize_id(params[:comapny_id]) unless params[:comapny_id].nil?
    end
    authorize :interact, :authorized?
    ibo_process_request do
       quests = Questionnaire.get_all_questionnaires(@cid,current_user)
      [{quests: quests,company_id: @cid}, nil]
    end
  end

  def questionnaire_create
    # authorize :interact, :authorized?
    authorize :interact, :create_questionnaire?
    ibo_process_request do
      aq = InteractBackofficeActionsHelper.create_new_questionnaire(@cid)
      unless aq.nil?
        QuestionnairePermission.create!(user_id: current_user.id, questionnaire_id: aq.id, company_id: @cid, level: :admin)
      end
      quests = Questionnaire.get_all_questionnaires(@cid,current_user)
      [quests, nil]
    end
  end

  def questionnaire_delete
    # authorize :interact, :authorized?
    authorize :interact, :create_questionnaire?
    ibo_process_request do
      qid = sanitize_id(params['qid'])
      q = Questionnaire.find(qid)
      Snapshot.drop_snapshot(q.snapshot_id)
      err = q.delete
      quests = Questionnaire.get_all_questionnaires(@cid,current_user)
      [quests, err]
    end
  end

  def questionnaire_update
    # authorize :interact, :authorized?
    ibo_process_request do
      aq = update_questionnaire_properties
      quests = Questionnaire.get_all_questionnaires(@cid,current_user)
      [{quests: quests, activeQuest: aq}, nil]
    end
  end
  
  def remove_participants
    # authorize :interact, :authorized?
    ibo_process_request do
      errors = InteractBackofficeHelper.remove_questionnaire_participans(@aq.id,current_user.id)
      q = Questionnaire.get_questionnaires([@aq.id],current_user)
      [{participants: [], questionnaire: q.first}, errors: [] ]
    end
  end

  def questionnaire_copy
    # authorize :interact, :authorized?
    authorize :interact, :create_questionnaire?
    ibo_process_request do

      qid = sanitize_id(params['qid'])
      rerun = sanitize_boolean(params['rerun'])

      aq = InteractBackofficeActionsHelper.create_new_questionnaire(@cid, qid, rerun)
      unless aq.nil?
        QuestionnairePermission.create!(user_id: current_user.id, questionnaire_id: aq.id, company_id: @cid, level: :admin)
      end
      quests = Questionnaire.get_all_questionnaires(@cid,current_user)
      [quests, nil]
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
    # authorize :interact, :authorized?
    ibo_process_request do
      InteractBackofficeActionsHelper.run_questionnaire(@aq)
      res_aq = @aq.as_json
      res_aq['state'] = Questionnaire.state_name_to_number(@aq['state'])

      [{questionnaire: res_aq}, nil]
    end
  end

  def questionnaire_close
    # authorize :interact, :authorized?
    # p = params.permit(:qid)
    # qid = sanitize_id(p[:qid])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
    ibo_process_request do
      @aq.update_attributes!(state: :processing)
      email = params[:email]
      CloseQuestionnaireJob.perform_later(@aq.id,email)
      res_aq = @aq.as_json
      res_aq['state'] = Questionnaire.state_name_to_number(@aq.state)

      [{questionnaire: res_aq}, nil]

      # p = params.permit(:qid)
      # qid = sanitize_id(p[:qid])
      # aq = Questionnaire.find(qid)
      # InteractBackofficeActionsHelper.close_questionnaire(aq)
      # res_aq = Questionnaire.find(qid).as_json
      # res_aq['state'] = Questionnaire.state_name_to_number(aq['state'])

      # [{questionnaire: res_aq}, nil]
    end
  end

  def update_test_participant
    # authorize :interact, :authorized?
    # qid = sanitize_id(quest[:id])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
    ibo_process_request do
      quest = params[:questionnaire]
      testUserName  = sanitize_alphanumeric_with_space(quest[:test_user_name])
      testUserEmail = sanitize_alphanumeric(quest[:test_user_email])
      testUserPhone = sanitize_alphanumeric(quest[:test_user_phone])

      @aq.update!(
        test_user_name: testUserName,
        test_user_email: testUserEmail,
        test_user_phone: testUserPhone
      )
      @aq.update!(state: :ready) if !InteractBackofficeHelper.test_tab_enabled(@aq)

      InteractBackofficeActionsHelper.send_test_questionnaire(@aq)
      testUserUrl = create_new_test(@aq)
      @aq = @aq.as_json
      @aq['state'] = Questionnaire.state_name_to_number(@aq['state'])
      [{questionnaire: @aq, test_user_url: testUserUrl}, nil]
    end
  end

  #################### Question #######################
  def get_questions
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
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
    # authorize :interact, :authorized?
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
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]

      qqid = sanitize_id(question['id'])
      title = question['title']
      body = question['body']
      min = sanitize_number(question['min'])
      max = sanitize_number(question['max'])
      active = sanitize_boolean(question['active'])

      qq = QuestionnaireQuestion.find(qqid)
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
        f_q = QuestionnaireQuestion.where(questionnaire_id: qq.questionnaire_id, active: true, is_funnel_question: true).first
        if f_q
          qq.update!(depends_on_question: f_q.id)
        end
      end

      # aq = qq.questionnaire
      @aq.update!(state: :questions_ready) if !participants_tab_enabled(@aq)
      @aq = @aq.as_json
      @aq['state'] = Questionnaire.state_name_to_number(@aq['state'])

      [{questionnaire: @aq}, nil]
    end
  end

  def question_delete
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
    ibo_process_request do
      id = sanitize_id(params['qqid'])
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
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # aq = Questionnaire.find(qid)
    # authorize aq, :admin?
    ibo_process_request do
      params.require(:question).permit!
      question = params[:question]
      # qid = params[:qid]
      cid = Questionnaire.find(@aq.id).try(:company_id)

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

      InteractBackofficeHelper.create_new_question(@cid, @aq.id, question, order)
      ['ok', nil]
    end
  end

  ################# Participants #######################

  def participants
    # authorize :interact, :authorized?
    ibo_process_request do
      # qid =        sanitize_id(params['qid'])
      page =       sanitize_number(params['page'])
      searchText = sanitize_alphanumeric(params['searchText'])
     ret, errors = prepare_data(@aq.id, page, searchText)
     [ret, errors]
    end
  end

  ##
  ## Return details about a particpant's progress in the qustionnaire
  ##
  def participant_status
    # authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params['qpid'])

      qp = QuestionnaireParticipant.find(qpid)
      quest_url = qp.create_link
      current_question = qp.current_questiannair_question_id
      emp = qp.employee
      name = "#{emp.first_name} #{emp.last_name}"
      # qid = qp.questionnaire_id

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

      questions = ActiveRecord::Base.connection.exec_query(sqlstr).to_a

      ## If there is a funnel question then the number of particpants per question
      ## is it the number the particpant has selected.
      ## otherwise it's the number of participants in the questionnaire
      funnel_question = QuestionnaireQuestion
        .where(questionnaire_id: @aq.id, active: true, order: 0).last
      qps_per_question = QuestionnaireParticipant
        .where(questionnaire_id: @aq.id).count - 1
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

  def questionnaire_status
    authorize :interact, :authorized?
    ibo_process_request do
      qid = sanitize_id(params['qid'])
      res = Questionnaire.get_questionnaire_status(qid)
      [res,nil]
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
    # authorize :interact, :authorized?
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      # qid = sanitize_id(par[:questionnaire_id])
      InteractBackofficeHelper.update_employee(@cid, par, @aq.id)
      participants, errors = prepare_data(@aq.id)
      # aq = Questionnaire.find(qid)
      if !InteractBackofficeHelper.test_tab_enabled(@aq)
        @aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: @aq}, errors]
    end
  end

  def participants_create
    # authorize :interact, :authorized?
    ibo_process_request do
      params.require(:participant).permit!
      par = params[:participant]
      # qid = sanitize_id(par[:questionnaire_id])
      # aq = Questionnaire.find(qid)
      InteractBackofficeHelper.create_employee(@cid, par, @aq)
      participants, errors = prepare_data(@aq.id)
      if !InteractBackofficeHelper.test_tab_enabled(@aq)
        @aq.update!(state: :notstarted)
      end

      [{participants: participants, questionnaire: aq}, errors]
    end
  end

  def participants_delete
    # authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      aq = InteractBackofficeHelper.delete_participant(qp,current_user.id)
      participants, errors = prepare_data(aq[:id])
      q = Questionnaire.get_questionnaires([aq.id],current_user)
      [{participants: participants, questionnaire: q.first}, errors]
    end
  end

  def participant_resend
    # authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      # aq = qp.questionnaire
      if @aq.state != 'sent'
        raise "Cant send messages to participants when questionnaire is not active"
      end
      InteractBackofficeActionsHelper.send_live_questionnaire(@aq, qp)
      [{}, nil]
    end
  end

  def close_participant_questionnaire
    # authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      qp.update(status: 3)
      [{}, nil]
    end
  end

  def set_active_questionnaire_question
    # authorize :interact, :authorized?
    ibo_process_request do
      qqid = sanitize_id(params[:qqid])
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      qp.update(current_questiannair_question_id: qqid)
      [{}, nil]
    end
  end

  def participant_reset
    # authorize :interact, :authorized?
    ibo_process_request do
      qpid = sanitize_id(params[:qpid])
      qp = QuestionnaireParticipant.find(qpid)
      # aq = qp.questionnaire
      # if aq.state != 'sent' && aq.state != 'ready' && aq.state != 'notstarted'
      #   raise "Cant reset participant when questionnaire is not active - it is #{aq.state}"
      # end
      qp.reset_questionnaire
      [{}, nil]
    end
  end

  def participants_get_emps
    # authorize :interact, :authorized?
    # qid = sanitize_id(params[:qid])
    # q = Questionnaire.find(qid)
    sid = @aq.snapshot_id
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
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # return nil if qid.nil?
    # sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    # return nil if sid.nil?
    sid = @aq.snapshot_id
    report_name = InteractBackofficeHelper.network_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_bidirectional_network
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # return nil if qid.nil?
    # sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    # return nil if sid.nil?
    sid = @aq.snapshot_id
    report_name = InteractBackofficeHelper.bidirectional_network_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_measures
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # return nil if qid.nil?
    # sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    # return nil if sid.nil?
    sid = @aq.snapshot_id
    report_name = InteractBackofficeHelper.measures_report(@cid, sid)
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: 'application/vnd.ms-excel')
  end

  def reports_survey
    # authorize :interact, :authorized?
    # qid = sanitize_id(params['qid'])
    # return nil if qid.nil?
    # sid = Questionnaire.find_by(id: qid).try(:snapshot_id)
    # return nil if sid.nil?
    sid = @aq.snapshot_id
    report_name = InteractBackofficeHelper.network_metrics_report(@cid, sid)
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
    # authorize :interact, :authorized?
    ibo_process_request do

      # file = sanitize_alphanumeric(params[:file_name])
      file = params[:file_name]
      file_name = file.original_filename
      empident = file_name[0..-5]

      # qid = sanitize_id(params[:qid])
      # quest = Questionnaire.find(qid)
      sid = @aq.snapshot_id

      emp = Employee.find_by(email: empident, snapshot_id: sid)
      emp = Employee.find_by(phone_number: empident, snapshot_id: sid) if emp.nil?
      err = []
      success = false
      if emp.nil?
        err << "No participant with email or phone: #{empident}"
      else
        eid = emp.id
        result = InteractBackofficeActionsHelper.upload_employee_img(file, eid) 
        err << result unless result.nil?
        # ret, err2 = prepare_data(qid)
        success=true
        # err.concat(err2) if !err2.nil?
      end
      # [{participants: ret}, err]
      [{img: file_name,success: success},err]
    end
  end

  def participants_refresh
    # authorize :interact, :authorized?
    ibo_process_request do
      ret, err = prepare_data(@aq.id)
      [{participants: ret}, err]
    end
  end

  def download_sample
    # authorize :interact, :authorized?
    file_name = InteractBackofficeHelper.create_example_excel
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end

  def download_participants_status
    # authorize :interact, :authorized?
    # qid = sanitize_id(params[:qid])
    file_name = InteractBackofficeHelper.create_status_excel(@aq.id)
    send_file(
      "#{Rails.root}/tmp/#{file_name}",
      filename: file_name,
      type: 'application/vnd.ms-excel')
  end

  ## Load employees from excel
  def upload_participants
    # authorize :interact, :authorized?

    ibo_process_request do
      emps_excel = params[:fileToUpload]
      # qid = sanitize_id(params[:qid])
      # aq = Questionnaire.find(qid)
      errors1 = ['No excel file uploaded']
      if !emps_excel.nil?
        sid = @aq.snapshot_id
        eids, errors2 = load_excel_sheet(@cid, params[:fileToUpload], sid, true)
        InteractBackofficeHelper.add_all_employees_as_participants(eids, @aq, current_user.id)
        CompanyFactorName.insert_factors(@cid,sid)
        ## Update the questinnaire's state if needed
        if !InteractBackofficeHelper.test_tab_enabled(@aq)
          if QuestionnaireParticipant.where(questionnaire_id: @aq.id).count > 1
            @aq.update!(state: :notstarted)
          end
        end
      end

      @q = Questionnaire.get_questionnaires([@aq.id],current_user)
      participants, errors3 = prepare_data(@aq.id)
      errors = []
      errors << errors1 unless errors1
      errors << errors2 unless errors2
      errors << errors3 unless errors3
      [{participants: participants, questionnaire: @q.first}, errors: errors ]
    end
  end

  def get_factors
    # authorize :interact, :authorized?
    ibo_process_request do

      # qid = sanitize_id(params['qid'])
      # q = Questionnaire.find(qid)
      sid = @aq.snapshot_id

      company_factors =
        CompanyFactorName
          .where(snapshot_id: sid, company_id: @cid)
          .order(id: :asc)

      [{factors: company_factors}, nil]
    end
  end


  def update_data_mapping
    # authorize :interact, :authorized?
    ibo_process_request do
      # qid = sanitize_id(params[:qid])
      # q =Questionnaire.find(qid)
      sid = @aq.snapshot_id
      factors = params[:factors]
      factors.each do |f|
        factor = CompanyFactorName.find(f['id'])
        factor.update!(display_name: f['display_name'])        
      end
    end
  end

  def save_k_factor
    # authorize :interact, :authorized?
    ibo_process_request do
      permitted = params.permit(:qqid, :qid, :k_factor)
      # qid = sanitize_id(permitted[:qid])
      gids = sanitize_ids(params[:gids])
      qqid = sanitize_id(permitted[:qqid])
      k = permitted[:k_factor]
      Rails.logger.info "qid=#{@aq.id}, gids=#{gids}, qqid=#{qqid}, k=#{k}"
      # q = Questionnaire.find(qid)
      sid = @aq.snapshot_id
      if @aq.update_attributes!(k_factor: k)
        qq = QuestionnaireQuestion.find(qqid)
        nid = qq.network_id
        res = QuestionnaireAlgorithm.get_question_score(sid,gids,nid,@cid,k)
        [{question_scores: res}, nil]
      else
        [{err: "error"}, nil]
      end
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

  def get_companies
    authorize :interact, :super_admin?
    ibo_process_request do
      companies = InteractBackofficeHelper.get_companies
      puts companies
      # companies = [{'id': 132,'name': 'companyA', 'surveyNum': 50, 'participantsNum': 1800},
      # {'id': 213,'name': 'companyB', 'surveyNum': 15, 'participantsNum': 80}]
      [{companies: companies,company_id: @cid}, nil]
    end
  end

  def company_create
    authorize :interact, :super_admin?
    ibo_process_request do
      company_name = params[:company_name]
      company = InteractBackofficeHelper.create_new_company(company_name)
      # [{company: company}, nil]
      companies = InteractBackofficeHelper.get_companies
      [{companies: companies}, nil]
    end
  end

  def company_update
    authorize :interact, :super_admin?
    ibo_process_request do
      params.require(:company).permit!
      company = params[:company]
      id = sanitize_id(company['id'])
      name = company['name']
      c = Company.find(id)
      c.update_attributes!(name: name)
      # errors=nil
      # unless c.update_attributes(name: name)
      #   errors = c.errors
      # end
      # puts errors
      companies = InteractBackofficeHelper.get_companies
      [{companies: companies}, nil]
    end
  end
  
  def get_users
    authorize :interact, :manage_users?
    ibo_process_request do
      users = InteractBackofficeHelper.get_company_users(@cid,current_user)
      quests = Questionnaire.select(:id,:name).where(company_id: @cid)
      [{users: users,questionnaires: quests.as_json}, nil]
    end
  end

  def user_create
    authorize :interact, :manage_users?
    ibo_process_request do
      params.require(:user).permit!
      user = params[:user]
      u = InteractBackofficeHelper.create_new_user(@cid,user)
      users = InteractBackofficeHelper.get_company_users(@cid,current_user)
      [{users: users}, nil]
   end
  end

  def user_update
    authorize :interact, :manage_users?
    ibo_process_request do
      params.require(:user).permit!
      user = params[:user]
      u = InteractBackofficeHelper.update_user(@cid,user)
      users = InteractBackofficeHelper.get_company_users(@cid,current_user)
      [{users: users}, nil]
    end
  end

  def user_delete
    authorize :interact, :manage_users?
    ibo_process_request do
      id = sanitize_id(params['uid'])
      user = User.find(id)
      user.destroy
      users = InteractBackofficeHelper.get_company_users(@cid,current_user)
      [{users: users}, nil]
    end
  end

  def update_user_questionnaire_permissions
    authorize :interact, :manage_users?
    ibo_process_request do
      user = InteractBackofficeActionsHelper.create_new_user(@cid)
      users = Company.users
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
