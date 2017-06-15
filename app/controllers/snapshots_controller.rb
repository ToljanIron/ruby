class SnapshotsController < ApplicationController
  def list_snapshots
    authorize :snapshot, :index?
    res = build_json
    render json: { snapshots: res }, status: 200
  end

  private

  def build_json
    res = []
    snapshots_arr = snapshotscope
    snapshots_arr.order(timestamp: :desc)
    snapshots_arr.each do |s|
      res.push s.pack_to_json
    end
    res
  end

  def snapshotscope
    SnapshotPolicy::Scope.new(current_user, Snapshot).resolve
  end
end
