include Mobile::QuestionnaireQuestionsHelper
include Mobile::Utils

class Mobile::QuestionsController < Mobile::MobileController

  def autosave
    json = params[:data]
    token = sanitize_alphanumeric(json['token'])
    qp = Mobile::Utils.authenticate_questionnaire_participant(token)
    unless qp
      render(json: { msg: 'Failed to get Question for Employee' }, status: 500)
      return
    end
    qp.autosave( json['replies'] )
    render text: 'ok'
  end

  def next
    json = params[:data]
    token = sanitize_alphanumeric(json['token'])
    qp = Mobile::Utils.authenticate_questionnaire_participant(token)
    unless qp
      render(json: { msg: 'Failed to get Question for Employee' }, status: 500)
      return
    end
    q_id = json['q_id']
    qp.update(in_continue_later_status: json['continue_later'], current_questiannair_question_id: q_id || qp[:current_questiannair_question_id]) unless json['continue_later'].nil?
    qp.update(in_continue_later_status: false) unless json['desktop'].nil?
    if json['replies'] && q_id
      Mobile::Utils.create_employees_connections(json, qp)
      qp.update_replies(json['replies'])
    end
    response = Mobile::QuestionnaireQuestionsHelper::build_next_question_response(qp)
    qp_status = QuestionnaireParticipant.update_questionnaire_participant_status(response[:status], response[:current_question_position], response[:total_questions])

    ## Once the test questionnaire has completed the first run the
    ## state is changed to ready, and from now on we can run the questionnaire.
    if qp.employee_id == -1 && qp_status == :completed && qp.questionnaire.state == 'notstarted'
      qp.questionnaire.update(state: :ready)
    end

    qp.update(current_questiannair_question_id: response[:q_id], status: qp_status)
    render json: response, status: 200
  end
end
