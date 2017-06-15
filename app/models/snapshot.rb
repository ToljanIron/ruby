class Snapshot < ActiveRecord::Base

  STATUS_INACTIVE            = 0
  STATUS_BEFORE_PRECALCULATE = 1
  STATUS_ACTIVE              = 2

  validates :company_id, presence: true
  enum snapshot_type: { weekly: 1, monthly: 2, yearly: 3 }
  enum status: [:inactive, :before_precalculate, :active]
  belongs_to :company
  has_many :friendships_snapshot
  has_many :advices_snapshot
  has_many :trusts_snapshots
  has_many :network_snapshot_data

  def pack_to_json
    res = {
      id: id,
      date: timestamp,
      name: name
    }
    return res
  end

  def self.create_snapshot_by_weeks(cid, date)
    end_date = calculate_snapshot_end_date(cid, date)
    name = create_snapshot_name_by_week(end_date, cid)
    if !snapshot_exists?(cid, name)
      snapshot = Snapshot.create!(
        name: name,
        snapshot_type: nil,
        timestamp: end_date,
        company_id: cid,
        status: :before_precalculate
      )
    else
      snapshot = Snapshot.find_by(company_id: cid, name: name, snapshot_type: nil)
    end
    return snapshot
  end

  def self.snapshot_exists?(cid, name, snapshot_type=nil)
    return (Snapshot.where(company_id: cid, name: name, snapshot_type: snapshot_type).size > 0)
  end

  def self.create_snapshot_name_by_week(end_date ,cid)
    return end_date.strftime('%Y-%U') if get_start_day_of_week(cid) == 7
    return end_date.strftime('%Y-%W')
  end

  def self.calculate_snapshot_end_date(cid, date)
    date = Date.parse(date)
    company_start_day_of_week = get_start_day_of_week(cid)
    date -= 1.day while date.cwday != company_start_day_of_week.to_i
    return date
  end

  def self.get_start_day_of_week(cid)
    company_start_day_of_week = CompanyConfigurationTable.where(comp_id: cid, key: 'start_day_of_week').first
    if !company_start_day_of_week.nil?
      company_start_day_of_week = company_start_day_of_week.value
    else
      company_start_day_of_week = 7
    end
    return company_start_day_of_week
  end

  def get_the_snapshot_before_the_last_one
    return Snapshot.order('timestamp DESC').where(company_id: company_id).offset(1).first
  end

  def get_the_snapshot_before_this
    date = timestamp.strftime("%Y-%m-%d %H:%M:%S")
    res = Snapshot.where("timestamp < ?", date).order('timestamp DESC').where(company_id: company_id).offset(1).first
    return self if res.nil?
    return Snapshot.where("timestamp < ?", date).order('timestamp DESC').where(company_id: company_id).offset(1).first
  end

  def self.last_snapshot_of_company(cid)
    return nil if cid.nil?
    snapshot = Snapshot.where(company_id: cid).order(:timestamp).last
    return snapshot.id if !snapshot.nil?
    snapshot_name = create_snapshot_name_by_week(Time.now ,cid)
    snapshot = Snapshot.create!(name: snapshot_name, timestamp: Time.now, company_id: cid)
    return snapshot.id
  end
end
