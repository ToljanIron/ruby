module MatrixConvertor
  require 'csv'
  module_function

  def convert(src, target, type)
    pairs = process_src_file(src)
    write_target_csv(pairs, target, type)
  end

  def process_src_file(src)
    raise "#{src} does not exist" unless File.exist? src
    @index_to_id_covertor = extract_external_ids(src)
    @id_to_index_covertor = @index_to_id_covertor.invert
    res = []
    CSV.readlines(src).each_with_index do|row, i|
      next if i == 0
      id = row[0]
      flaged_indexes(row).each do |flaged_index|
        res.push [id, @index_to_id_covertor[flaged_index]]
      end
    end
    return res
  end

  def extract_external_ids(src)
    arr = CSV.read(src)[0]
    hash = Hash[arr.each_with_index.map { |value, index| [index, value] }]
    return hash
  end

  def flaged_indexes(row_arr)
    res = []
    row_arr.each_with_index do |val, i|
      next if i == 0
      res.push(i) if val.to_i == 1
    end
    return res
  end

  def create_heaser_by(type)
    case type
    when 'advice'
      return %w(employee_exteranl_id  advisor_external_id relation_type Snapshot)
    when 'trust'
      return %w(employee_exteranl_id  trusted_external_id relation_type Snapshot)
    when 'friendship'
      return %w(employee_exteranl_id  friend_external_id  relation_type Snapshot)
    when 'managment'
      return %w(manager_external_id employee_external_id  relation_type Delete)
    end
  end

  def write_target_csv(pairs, target, type)
    CSV.open(target, 'w') do |csv|
      header = create_heaser_by(type)
      csv << header if header
      if type == 'managment'
        pairs.each { |p| csv << [p[0], p[1], 1, 'direct'] }
      else
        pairs.each { |p| csv << [p[0], p[1], 1, 'Monthly-2015-09-1'] }
      end
    end
  end
end
