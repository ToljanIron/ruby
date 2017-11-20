module SnapshotsHelper

  def get_last_snapshots_of_each_month(cid, limit)
    sqlstr = "SELECT id AS sid, name, month, quarter, half_year, year
              FROM (
                SELECT
                  snapshots.id,
                  name,
                  company_id,
                  month,
                  quarter,
                  half_year,
                  year,
                  timestamp,
                  max(timestamp) OVER (PARTITION BY month) AS max_timestamp
                FROM snapshots
                WHERE company_id = #{cid}
              ) t
              WHERE timestamp = max_timestamp AND company_id = #{cid}
              ORDER BY timestamp ASC
              LIMIT #{limit}"
    sqlres = ActiveRecord::Base.connection.select_all(sqlstr)
    return sqlres
  end

  def get_last_snapshots_of_month_ids(cid, limit)
    return get_last_snapshots_of_month(cid, limit).pluck('id')
  end
end
