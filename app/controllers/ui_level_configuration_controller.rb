class UiLevelConfigurationController < ApplicationController
  include UiLevelConfigurationHelper
  include CdsUtilHelper
  def get_ui_levels
    authorize :ui_level_configuration, :index?
    cid = current_user.company_id
    cache_key = "get_ui_levels-#{cid}"
    ui_levels = cache_read(cache_key)
    if ui_levels.nil?
      comp = Company.find(cid)
      ui_levels = build_ui_level_tree(cid)               if !comp.questionnaire_only?
      ui_levels = build_ui_level_questionnaire_only(cid) if  comp.questionnaire_only?
      cache_write(cache_key, ui_levels)
    end
  render json: Oj.dump(ui_levels)
  end
end
