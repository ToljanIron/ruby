require 'csv'

csv_file = ENV['csv']
cid = ENV['cid'].to_i

puts "csv: #{csv_file}"
puts "cid: #{cid}"

first_names = []
last_names = []
CSV.foreach(csv_file).each do |row|
  first_names << row[1]
  last_names << row[3]
end
Employee.where(company_id: cid).each do |emp|
  first_name = nil
  last_name = nil
  first_names.delete_if { |name| first_name = name if first_name.nil? }
  last_names.delete_if { |name| last_name = name if last_name.nil? }
  emp.update(first_name: first_name, last_name: last_name)
end
