module CdsUtilHelper
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  def safe_titleize(str)
    return nil if str.nil?
    return str.titleize if !str.match(/^[a-zA-Z \-]*$/).nil?
    return str
  end

  def self.convert_str_to_date(str)
    return Date.parse(str) if str
  end

  def self.validate_email(str)
    return str =~ VALID_EMAIL_REGEX
  end

  def self.calc_age_from_now(date)
    return nil unless date
    now = DateTime.now
    return now.year - date.year
  end

  def self.calc_age_group(int)
    return nil unless int
    case int
    when 15..24
      res = AgeGroup.where(name: '15-24').first.try(:id)
    when 25..34
      res =  AgeGroup.where(name: '25-34').first.try(:id)
    when 35..44
      res =  AgeGroup.where(name: '35-44').first.try(:id)
    when 45..54
      res =  AgeGroup.where(name: '45-54').first.try(:id)
    when 55..64
      res =  AgeGroup.where(name: '55-64').first.try(:id)
    else
      res =  AgeGroup.where(name: '65+').first.try(:id)
    end
    return res
  end

  def self.calc_seniority(date)
    return nil unless date
    now = Time.now
    date = date.to_time
    diff = (now - date)
    year = (diff / 1.year).to_i
    # month = ((diff / 1.month) % 12).to_i
    case year
    when 0
      s = year.to_s
    when 1..4
      s = year.to_s + 'Y'
    else
      s = '5Y+'
    end
    return Seniority.where(name: s).first.try(:id)
  end

  def self.get_manager(eid, type)
    manager_relation = EmployeeManagementRelation.find_by(employee_id: eid, relation_type: type)
    m_id = Employee.find(manager_relation.manager_id).id if manager_relation
    return m_id
  end

  def self.get_level(emp)
    return nil unless emp
    level = 0
    formal_managment = EmployeeManagementRelation.find_by(employee_id: emp.id, relation_type: 'direct')
    while formal_managment
      id = formal_managment.manager_id
      level += 1
      formal_managment = EmployeeManagementRelation.find_by(employee_id: id, relation_type: 'direct')
    end
    return level
  end

  def self.get_subordinates(emp)
    eids = Employee.by_company(emp[:company_id]).ids
    managment = EmployeeManagementRelation.where(employee_id: eids, relation_type: 0)
    managment_active_record_relation = emp.extract_descendants_with_parent(managment, emp.id)
    return managment_active_record_relation
  end

  def self.get_max(arr)
    max = -1
    arr.each do |o|
      max = o[:measure] if o[:measure] > max
    end
    return max
  end

  def self.choose_random_color
    all_colors = Color.all
    color_index = rand(all_colors.all.size) + 1
    all_colors.find(color_index).id
  end

  def self.upload_to_s3(full_path)
    return if Rails.env == 'test'
    s3_access_key = ENV['s3_access_key']
    s3_secret_access_key = ENV['s3_secret_access_key']
    bucket_name = ENV['bucket_name']
    fail 'Util:upload_to_s3 - missing S3 credentials' unless s3_access_key && s3_secret_access_key && bucket_name
    s3 = AWS::S3.new(access_key_id: s3_access_key, secret_access_key: s3_secret_access_key)
    key = File.basename(full_path)
    s3.buckets[bucket_name].objects[key].write(file: full_path)
  end

  def self.run_syncronic_post(url, body)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Post.new uri
      request.body = body
      response = http.request request
      return response.body
    end
    '{}'
  end

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

  ############################## SQL helper functions ################################3
  def is_sql_server_connection?
    return ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::SQLServerAdapter)
  end

  def sql_concat(a,b)
    return "concat(#{a}, ' ', #{b})" if is_sql_server_connection?
    return "#{a} || ' ' || #{b}"     if !is_sql_server_connection?
  end

  def sql_check_boolean(field, value)
    raise 'value should be true or false' if (value.class != FalseClass && value.class != TrueClass)
    val = value ? 1 : 0
    return "#{field} is #{value}" if !is_sql_server_connection?
    return "#{field} = #{val}" if is_sql_server_connection?
  end

  ############################## Statistics functions ################################3
  def array_mean(a)
    raise 'Nil argument' if a.nil?
    raise 'Argument is not an Array' if !a.kind_of?(Array)
    raise 'Empty array' if a.count == 0
    res = 0
    a.each { |e| res += e }
    return (res.to_f / a.count).round(3)
  end

  def array_sd(a)
    raise 'Nil argument' if a.nil?
    raise 'Argument is not an Array' if !a.kind_of?(Array)
    raise 'Empty array' if a.count <= 1
    mean = array_mean(a)
    res = 0
    a.each { |e| res += (e - mean) ** 2}
    return Math.sqrt(res.to_f / (a.count - 1)).round(3)
  end

  def array_median(a)
    stats = DescriptiveStatistics::Stats.new(a)
    return stats.median
  end
end
