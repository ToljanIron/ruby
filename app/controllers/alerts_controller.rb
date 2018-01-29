class AlertsController < ApplicationController
  include Asspects

  def get_alerts
    authorize :alert, :index?
    measures_return_result do
      sp = {cid: current_user.company_id}

      permitted = params.permit(:gids, :curr_interval)
      gids = permitted[:gids]
      if gids.nil?
        sp[:gids] = []
      else
        gids = gids.split(',').map(&:sanitize_integer)
        sp[:gids] = current_user.filter_authorized_groups(gids)
      end
      sp[:currsid] = permitted[:curr_interval].sanitize_is_alphanumeric_with_slash
      measures_cache_result('measures_return_result', sp) do
        ret = Alert.alerts_for_snapshot(sp[:cid], sp[:currsid], sp[:gids])
        AlertsHelper.format_alerts(ret)
      end
    end
  end

  def acknowledge_alert
    authorize :alert, :update?

    measures_return_result do
      sp = {cid: current_user.company_id}
      alid = params[:alid]
      sp[:alid] = alid.to_i
      if !alid.nil?
        al = Alert.where(company_id: sp[:cid], id: sp[:alid]).last
        al.mark_viewed if !al.nil?
      end
      {status: 'ok'}
    end
  end
end
