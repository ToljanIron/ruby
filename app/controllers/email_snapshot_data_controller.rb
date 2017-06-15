class EmailSnapshotDataController < ApplicationController
  include EmailSnapshotDataHelper
  include AdviseMeasureHelper
  include CalculateMeasureHelper

  # API/get_network_snapshot
  def network_snapshot
    authorize :email_snapshot_data, :index?
    with_others = to_boolean(params[:others])
    degree_type = to_boolean(params[:degree_type])
    last_snapshot = snapshotscope.order('created_at').last
    snapshot_list = get_snapshot_node_list(last_snapshot.id, with_others, -1)
    degree_list = create_measure_list(snapshot_list, degree_type)
    @weight_arr = weight_algorithm(snapshot_list)
    relation = snapshot_list.each_with_index.map { |p, i| format_snapshot(p, i) }
    render json: { relation: relation, degree_list: degree_list }
  end

  # API/get_advice_measure
  def advice_measure
    authorize :email_snapshot_data, :index?
    time_filter = params[:time_filter] || 1
    with_others = to_boolean(params[:others_status])
    time_filter = time_filter.to_i
    company_id = current_user.company_id
    res = create_advice_measure(time_filter, company_id, with_others)
    if res
      render json: { res: res, exsists: true }
    else
      render json: { exsists: false }
    end
    return
  end

  private

  def to_boolean(str)
    str == 'true'
  end

  def snapshotscope
    SnapshotPolicy::Scope.new(current_user, Snapshot).resolve
  end
end
