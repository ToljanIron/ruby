require 'oj'
require 'oj_mimic_json'

include SnapshotsHelper
include CdsUtilHelper

class SnapshotsController < ApplicationController
  def list_snapshots
    authorize :snapshot, :index?
    res = build_json
    render json: { snapshots: res }, status: 200
  end

  def get_snapshots
    authorize :snapshot, :index?
    limit = params[:limit] || 20
    cid = current_user.company_id
    cache_key = "get_snapshots-lim#{limit}-cid#{cid}"
    res = cache_read(cache_key)
    if res.nil?
      snapshots = Snapshot.where(company_id: cid, status: :active).order('timestamp DESC').limit(20)
      res = []
      snapshots.each do |s|
        res << {sid: s.id, name: s.name}
      end
      res = Oj.dump(res)
      cache_write(cache_key, res)
    end
    render json: res
  end

  def get_time_picker_snapshots
    authorize :snapshot, :index?

    cid = current_user.company_id
    limit = params[:limit].to_i
    limit = limit > 24 ? 24 : limit

    res = get_last_snapshots_of_each_month(cid, limit)
    res = Oj.dump(res)

    render json: res
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
