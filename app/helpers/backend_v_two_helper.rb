module BackendVTwoHelper
  ##################### CACHE ############################3
  def to_cache?
    return true if Rails.env.production? || Rails.env.onpremise?
    return false
  end

  def cache_read(key)
    fail 'Key is nil' if key.nil?
    return Rails.cache.fetch(key) if to_cache?
    return nil
  end

  def cache_write(key, value)
    fail 'Key is nil' if key.nil?
    Rails.cache.write(key, value, expires_in: 24.hours) if to_cache?
  end

  def cache_delete(key, _value)
    fail 'Key is nil' if key.nil?
    Rails.cache.delete(key) if to_cache?
  end

  def cache_delete_all
    Rails.cache.clear if to_cache?
  end

  def read_or_calculate_and_write(key) # takes a block, a returned value of which will be written to cache and returned
    result = cache_read(key)
    return result unless result.nil?
    result = yield
    cache_write(key, result)
    return result
  end

  def self.company_reset(cid, sid = nil, delete_structure=false)
    raise "No company ID provided" if (cid == 0 || cid == -1 || cid.nil?)
    company = Company.find_by(id: cid)
    raise "Company not found for ID: #{cid}" if company.nil?

    if delete_structure
      sqlstr = "delete from employee_management_relations where manager_id in (select id from employees where company_id = #{cid})"
      ActiveRecord::Base.connection.execute(sqlstr)
      Employee.where(company_id: cid).delete_all
      Group.where(company_id: cid).delete_all
      return true
    end

    snapshot = nil
    if (!sid.nil? && sid > 0)
      puts "Looking for snapshot: #{sid}"
      snapshot = Snapshot.find_by(id: sid)
      raise "Snapshot: #{sid} not found" if (snapshot.nil?)
    else
      puts "Looking for latest snapshot"
      sid = Snapshot.where(company_id: cid).order(:timestamp).last.id
    end

    NetworkSnapshotData.where(company_id: cid, snapshot_id: sid).delete_all
    RawDataEntry.where(company_id: cid).delete_all
    CdsMetricScore.where(snapshot_id: sid).delete_all

    return true
  end
end
