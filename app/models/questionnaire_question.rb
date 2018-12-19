class QuestionnaireQuestion < ActiveRecord::Base
  belongs_to :question
  has_many :question_replies
  belongs_to :questionnaire
  belongs_to :network_name, class_name: 'NetworkName', foreign_key: :network_id

  def init_replies(questionnaire_participants)
    ActiveRecord::Base.transaction do
      questionnaire_participants.each do |e_1|
        questionnaire_participants.each do |e_2|
          next if e_1 == e_2
          q = QuestionReply.find_or_create_by(questionnaire_id: self.questionnaire.id, questionnaire_question_id: id, questionnaire_participant_id: e_1[:id], reffered_questionnaire_participant_id: e_2[:id])
          q.answer = nil
        end
      end
    end
  end

  def dependent_questions
    return Question.where(depends_on_question: order)
  end

  def questionnaire_participants
    return Questionnaire.find(questionnaire_id).questionnaire_participant
  end

  def question_position
    orders_inx = questionnaire
                   .questionnaire_questions
                   .where(active: true)
                   .order(:order).pluck(:order)
                   .index(order)
     return (orders_inx + 1)
  end

  private

end
