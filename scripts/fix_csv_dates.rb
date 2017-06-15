def fix_date(date)
  parts = date.split('/')
  return "#{parts[2]}-#{parts[1]}-#{parts[0]}"
end

lines = File.readlines("CSV1E.csv")
puts lines.shift  ## Print the headline
lines.each do |line|
  fields = line.split(',')
  bdate = fields[9]
  fields[9] = fix_date(bdate)
  wdate = fields[12]
  fields[12] = fix_date(wdate)
  new_fields = fields.join(',')
  puts new_fields
end

