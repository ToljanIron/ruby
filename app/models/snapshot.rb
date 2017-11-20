class Snapshot < ActiveRecord::Base

  STATUS_INACTIVE            = 0
  STATUS_BEFORE_PRECALCULATE = 1
  STATUS_ACTIVE              = 2

  validates :company_id, presence: true
  validates :timestamp, presence: true
  enum snapshot_type: { weekly: 1, monthly: 2, yearly: 3 }
  enum status: [:inactive, :before_precalculate, :active]
  belongs_to :company
  has_many :network_snapshot_data

  before_save do
    self.month = get_month
    self.quarter = get_quarter
    self.half_year = get_half_year
    self.year = get_year
  end

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

  def self.drop_snapshot(sid)
    snapshot = Snapshot.find(sid)
    raise "Snapshot: #{sid} not found" if snapshot.nil?
    CdsMetricScore.where(snapshot_id: sid).delete_all
    NetworkSnapshotData.where(snapshot_id: sid).delete_all
    Employee.by_snapshot(sid).delete_all
    Group.by_snapshot(sid).delete_all
    snapshot.delete
  end

  def self.most_recent_snapshot(sids)
    snapshot = Snapshot.find(sids)
    raise "Snapshots: #{sids} not found" if snapshot.nil?
    return Snapshot.where(id: sids).order(:timestamp).last
  end



  ######################## Intervals ####################

  MONTHS_HASH = {
    'Jan'=> 1,
    'Feb'=> 2,
    'Mar'=> 3,
    'Apr'=> 4,
    'May'=> 5,
    'Jun'=> 6,
    'Jul'=> 7,
    'Aug'=> 8,
    'Sep'=> 9,
    'Oct'=> 10,
    'Nov'=> 11,
    'Dec'=> 12,
  }

  def get_month
    timestamp.strftime('%b/%y')
  end

  def get_quarter
    month = timestamp.strftime('%m').to_i
    year = timestamp.strftime('%y')
    return "Q1/#{year}" if ( [1,2,3].include?(month) )
    return "Q2/#{year}" if ( [4,5,6].include?(month) )
    return "Q3/#{year}" if ( [7,8,9].include?(month) )
    return "Q4/#{year}" if ( [10,11,12].include?(month) )
  end

  def get_half_year
    month = timestamp.strftime('%m').to_i
    year = timestamp.strftime('%y')
    return "H1/#{year}" if ( [1,2,3,4,5,6].include?(month) )
    return "H2/#{year}" if ( [7,8,9,10,11,12].include?(month) )
  end

  def get_year
    timestamp.strftime('%Y')
  end

  def self.field_from_interval_type(interval_type)
    raise 'Nil interval_type not alowed' if interval_type.nil?
    return 'month' if interval_type == 'By Month'
    return 'quarter' if interval_type == 'By Quarter'
    return 'half_year' if interval_type == 'By 6 Months'
    return 'year' if interval_type == 'By Year'
    raise "Unknown interval_type: #{interval_type}"
  end

  def self.last_snapshot_in_interval(interval, snapshot_field)
    return Snapshot
             .select(:id)
             .where("? = '?'", interval, snapshot_field)
             .order('timestamp desc')
             .first[:id]
  end

  def self.compare_periods(p1, p2)
    if p1[0] == '2'     ## Order as year
      return p1 <=> p2

    elsif p1[0] == 'Q' || p1[0] == 'H' ## Order as Quarter or Half year
      year1 = p1[3..-1]
      year2 = p2[3..-1]
      comp = year1 <=> year2
      return comp if comp != 0
      q1 = p1[0..1]
      q2 = p2[0..1]
      return q1 <=> q2

    else                ## Order as month
      year1 = p1[4..-1]
      year2 = p2[4..-1]
      comp = year1 <=> year2
      return comp if comp != 0
      m1 = MONTHS_HASH[p1[0..2]]
      m2 = MONTHS_HASH[p2[0..2]]
      return m1 <=> m2
    end
  end
end
