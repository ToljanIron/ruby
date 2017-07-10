
module RawDataEntriesHelper
  def process_request(request_parsed_to_csv)
    company = request_parsed_to_csv['company']
    zipped_str = Base64.decode64(request_parsed_to_csv['file'])
    begin
      company_id = Company.where(name: company)[0].id
      @c_id = company_id
    rescue
      raise "process_request: Cannot find company by name '#{company}'"
    end
    return if zipped_str.empty?
    csv = zip_to_csv(zipped_str)
    data = CSV.parse(csv)
    data.shift
    data.each do |element|
      element[0] = element[0].gsub("'", "") if !element[0].nil?
      element[2] = element[2].gsub("'", "") if !element[2].nil?
      element[3] = element[3].gsub("'", "") if !element[3].nil?
      element[4] = element[4].gsub("'", "") if !element[4].nil?
      element[5] = element[5].gsub("'", "") if !element[5].nil?
      element[2] = element[2].gsub("'", "") if !element[2].nil?
      element[9] = element[9].gsub("'", "") if !element[9].nil?
      element[8] = format_date(element[8])
      element[7] = element[7] == 'true' ? true : false
      element.map! do |el|
        el = wrap_array_to_str(el) if el.is_a?(String) && !el.nil? && el.start_with?('[') && el.end_with?(']')
        "#{el}"
      end

      rec = RawDataEntry.where(
        company_id: company_id,
        msg_id:   element[0],
        from:     element[2].downcase,
      ).first

      if (rec.nil?)
        RawDataEntry.create!(
          company_id: company_id,
          msg_id:   element[0],
          from:     element[2].downcase,
          date:     element[8],
          reply_to_msg_id: element[1],
          to:       element[3].downcase,
          cc:       element[4].downcase,
          bcc:      element[5].downcase,
          priority: element[6],
          fwd:      element[7],
          subject:  element[9])
      end
    end
  end

  def format_date(d)
    return d[0..9]
  end

  def zip_to_csv(zipped_str)
    ZipRuby::Archive.open_buffer(zipped_str) do |archive|
      archive.each do |entry|
        return entry.read
      end
    end
  rescue
    return -1
  end

  def wrap_array_to_str(str)
    res = []
    if str.length > 2 && str[0] == '[' && str[-1] == ']'
      str = str[1..-2]
      res = str.split(',')
      res.map! { |s| s.strip[1..-2].strip }
    end
    return '{' + res.join(',') + '}'
  end
end
