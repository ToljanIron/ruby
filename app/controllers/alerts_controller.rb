class AlertsController < ApplicationController
  include Asspects

  def get_alerts
    authorize :alert, :index?

    measures_return_result do
      sp = {cid: current_user.company_id}

      permitted = params.permit(:gids, :sid)
      gids = permitted[:gids]
      if gids.nil?
        sp[:gids] = []
      else
        gids = gids.split(',').map(&:sanitize_integer)
        sp[:gids] = current_user.filter_authorized_groups(gids)
      end
      sp[:sid] = permitted[:sid].to_i.sanitize_integer
      measures_cache_result('measures_return_result', sp) do
        Alert.alerts_for_snapshot(sp[:cid], sp[:sid], sp[:gids])
      end
    end
  end

  def discard_alerts
    authorize :alert, :update?

    measures_return_result do
      sp = {cid: current_user.company_id}

      permitted = params.permit(:alids)
      alids = permitted[:alids]
      if alids.nil?
        sp[:alids] = []
      else
        alids = alids.split(',').map(&:sanitize_integer)
        sp[:alids] = current_user.filter_authorized_groups(alids)
      end
      Alert.where(company_id: sp[:cid], id: sp[:alids]).each do |alert|
        alert.discard
      end
      {status: 'ok'}
    end
  end
end
