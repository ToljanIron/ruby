include  Mobile::QuestionnaireQuestionsHelper
include Mobile::Utils
class Mobile::QuestionnaireQuestionsController < Mobile::MobileController
  def update_questionnaire_question
    attrs = Mobile::Utils.convert_strings_to_keys params[:question]
    Mobile::QuestionnaireQuestionsHelper.update_question attrs
    redirect_to select_company_path(tab: 2, questionnaire_id: attrs[:questionnaire_id])
  end
end