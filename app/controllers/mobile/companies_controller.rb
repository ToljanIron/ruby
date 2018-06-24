include Mobile::CompaniesHelper
require './app/helpers/mobile/questionnaire_helper.rb' 
include CdsUtilHelper
class Mobile::CompaniesController < Mobile::MobileController
  def show
    load_companies
    render 'show', layout: 'mobile_application'
  end

  def update
    attrs = Utils.convert_strings_to_keys params[:company]
    update_company_by_id attrs
    redirect_to root_path
  end

  def create
    attrs = Utils.convert_strings_to_keys params[:company]
    create_update_company_by_name(attrs)
    redirect_to root_path
  end

  def remove
    diactivate_company_by_id(params[:id].to_i)
    redirect_to root_path
  end

  def select
    unless @current_user.admin?
      redirect_to root_path
      return
    end
    @show_tab = params[:tab].to_i || 1
    select_company_by_id(@current_user.company_id)
    @questionnaire = Mobile::QuestionnaireHelper.get_questionnaire_details(params[:questionnaire_id])
    @questionnaire_questions = @questionnaire[:questions]
    @current_questionnaire = Questionnaire.where(id: params[:questionnaire_id].to_i, company_id: @current_user.company_id).first
    # @on_premise = ENV['ON_PREMISE'] == 'true'
    if @curr_company && @current_questionnaire
      @current_questionnaire.check_replies_status if @current_questionnaire
      render 'show_company', layout: 'mobile_application'
    else
      redirect_to root_path
    end
  end
end
