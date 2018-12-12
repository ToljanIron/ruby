# frozen_string_literal: true
include Mobile::QuestionnaireHelper
module Mobile
  class QuestionnaireController < Mobile::MobileController
    def get_questionnaires_state
      cid = current_user.company_id
      state = Questionnaire.where(company_id: cid).last.state
      render json: { questionnaire_status: state }
    end

    def send_questionnaire
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      send_only_to_unstarted = sanitize_boolean(params[:send_only_to_unstarted])
      sender_type = sanitize_alphanumeric(params[:sender_type])
      q = Questionnaire.where(id: questionnaire_id, company_id: @current_user.company_id).first
      raise "Error in send_questionnaire questionnaire_id #{questionnaire_id} not found in company_id #{@current_user.company_id}" unless q
      q.send_q(send_only_to_unstarted, sender_type)
      redirect_to select_company_path(tab: 3, questionnaire_id: questionnaire_id)
    end

    def reset_questionnaire_for_emp
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      eid = sanitize_id(params[:eid]).to_i
      q = Questionnaire.where(id: questionnaire_id, company_id: @current_user.company_id).first
      q.reset_questionnaire_for_emp(eid)
      render json: true
    end

    def send_questionnaire_for_emp
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      eid = sanitize_id(params[:eid]).to_i
      q = Questionnaire.where(id: questionnaire_id, company_id: @current_user.company_id).first
      raise "Error in send_questionnaire questionnaire_id #{questionnaire_id} not found in company_id #{@current_user.company_id}" unless q
      q.send_questionnaire_to_emp(eid)
      render json: true
    end

    def send_questionnaire_to_all_ajax
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      q = Questionnaire.where(id: questionnaire_id, company_id: @current_user.company_id).first
      raise "Error in send_questionnaire questionnaire_id #{questionnaire_id} not found in company_id #{@current_user.company_id}" unless q
      q.delay.resend_questionnaire_to_incomplete
      render json: true
    end

    def generate_questionnaire_report
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      q = Questionnaire.where(id: questionnaire_id, company_id: @current_user.company_id).first
      raise "Error in send_questionnaire questionnaire_id #{questionnaire_id} not found in company_id #{@current_user.company_id}" unless q
      report_path = q.generate_report

      render json: {report_path: report_path, status: true}
    end

    def active_employees
      quest_id = sanitize_id(params['questionnaire_id']).to_i
      empsarr = sanitize_ids(params['emps_arr'])
      emps_arr = JSON.parse(empsarr)
      Mobile::QuestionnaireHelper.set_active_employees(quest_id, emps_arr)
      redirect_to select_company_path(tab: 1, questionnaire_id: quest_id)
    end

    def download_csv
      questionnaire_id = sanitize_id(params[:questionnaire_id]).to_i
      q = Questionnaire.find(questionnaire_id)
      questionnaire_questions = q.questionnaire_questions
      if questionnaire_questions
        c = q.company
        filename = c.name
        res = []

        questionnaire_questions.each do |qq|
          res.push qq.to_csv
        end
        res = res.join("\n\n")
        send_data res, filename: "#{filename}.csv"
      else
        redirect_to :back
      end
    end

    def capture_quesitonnaire_in_snapshot
      questionnaire = Questionnaire.last
      Rails.cache.clear
      questionnaire.delay.freeze_questionnaire
      render json: { last_submitted: Questionnaire.find(questionnaire.id).last_submitted }
    end

    def get_questionnaires_for_settings_tab
      cid = current_user.company_id
      questionnaires = Questionnaire.where(company_id: cid).order(:state).order(created_at: :desc)
      res = []
      questionnaires.each do |quest|
        q = quest.attributes
        q[:last_submitted] = quest.last_submitted
        res.push(questionnaire: q,
                 num_of_active: Mobile::QuestionnaireHelper.get_questionnair_active_participants(quest),
                 completed_participants: Mobile::QuestionnaireHelper.get_questionnair_completed_percentage_participants(quest))
      end
      render json: { questionnaires: res }
    end

    def get_questionnaire_participants
      cid = current_user.company_id
      relevant_questionnaires = Questionnaire.where(company_id: cid)
      res = []
      questions = QuestionnaireQuestion.where(questionnaire_id: relevant_questionnaires.pluck(:id))

      relevant_questionnaires.each do |q|
        other = Employee.where(email: 'other@mail.com').first
        other = 0 unless other
        participants_employees = q.questionnaire_participant
                                  .where('active = ? and employee_id != ? ', true, other)
                                  .map do |e|
                                    { 'employee_id' => e.employee_id,
                                      'status' => e.status == 'entered' ? 'in_process' : e.status,
                                      'answered' => if e.current_questiannair_question_id
                                                      questions.find(e.current_questiannair_question_id)[:order] - (e.status == 'in_process' ? 1 : 0)
                                                    else
                                                      0
                                                    end,
                                      'last_action' => e.last_action(q.id) }
                                  end
        total = q.questionnaire_participant.where(active: true).count
        completed = total.zero? ? 0 : (q.questionnaire_participant.where(status: 3, active: true).count.to_f / total).round(2) * 100
        in_progress = total.zero? ? 0 : (q.questionnaire_participant.where(status: [1, 2], active: true).count.to_f / total).round(2) * 100
        havent_started = (100.00 - in_progress - completed).to_f.round(2)
        havent_started = havent_started.strip.to_s + '%'
        completed = completed.to_f.round(2).strip.to_s + '%' if completed
        in_progress = in_progress.to_f.strip.to_s + '%' if in_progress
        questionnaire_statistics = { total: total, completed: completed, in_progress: in_progress, havent_started: havent_started }
        res.push(q_id: q.id, participants_employees: participants_employees, questionnaire_statistics: questionnaire_statistics)
      end
      render json: { questionnaire_array: res }
    end
  end
end
