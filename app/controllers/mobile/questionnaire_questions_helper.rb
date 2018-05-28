module Mobile::QuestionnaireQuestionsHelper

  def create_update_question(attrs)
    attrs[:active] = true
    #ap attrs
    if attrs[:order].empty?
      questions = Company.find(attrs[:company_id].to_i).questions
      if questions.count > 0
        order = questions.pluck(:order).compact.max + 1
      else
        order = 1
      end
      attrs[:order] = order
    end
    Question.create(attrs)
  end

  def update_question_by_id(attrs)
    q = Question.find(attrs[:id])
    q.update(attrs) if q
  end

  def diactivate_question_by_id(id)
    q = Question.find(id)
    Question.where(depends_on_question: q.order).each do |dq|
      dq.update(depends_on_question: nil)
    end
    q.update(active: false, order: nil)
  end

  def is_dependent?(question_id)
    q = QuestionnaireQuestion.find(question_id)
    return q[:depends_on_question] == 1
  end

  def update_question(attributes)
    q = QuestionnaireQuestion.where(id: attributes[:id], questionnaire_id: attributes[:questionnaire_id]).first
    return unless q
    q.update_attributes(attributes)
  end

  def self.build_next_question_response(qp)
    response = {}
    questionnaire_question, response[:status] = qp.find_next_question
    replies = qp.all_replies_for_questionnaire_question(questionnaire_question.id)

    ## shuffling repolies here so the app will display people at random order.
    ## This gives the questionnaire a higher statistical accuracy
    response[:replies] = replies.shuffle!

    response[:min] = questionnaire_question.min || response[:replies].count
    response[:max] = questionnaire_question.max || response[:replies].count
    response[:token] = qp.token
    response[:current_emp_id] = qp.employee_id
    response[:question_title] = questionnaire_question.title
    response[:question] = questionnaire_question.body
    response[:q_id] = questionnaire_question.id
    response[:total_questions] = qp.questionnaire.size
    response[:current_question_position] = qp.questionnaire.question_position(questionnaire_question.id)
    response[:is_dependent] = is_dependent?(questionnaire_question.id)
    return response
  end
end
