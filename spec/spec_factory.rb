def create_node_entry(femp, temp, snapshot_id, inc, is_const_inc = false)
  node = {:employee_from_id=> femp.id, :employee_to_id => temp.id, :snapshot_id => snapshot_id}
  # node = NetworkSnapshotData.new(:from_employee_id=> femp.id, :to_employee_id => temp.id, :snapshot_id => snapshot_id)
  (1..18).each do |i|
    if is_const_inc
      node['n'+i.to_s] = inc
    else
      node['n'+i.to_s] = i+inc
    end
  end
  NetworkSnapshotData.create_email_adapter(node)
  # node.save!
end



# def create_node_entry_to_cc_bcc(femp, temp, snapshot_id, to_value, cc_value, bcc_value)     #DEAD CODE ASAF BYEBUG
#   node = EmailSnapshotData.new(:employee_from_id=> femp.id, :employee_to_id => temp.id, :snapshot_id => snapshot_id)
#   (1..18).each do |i|
#     if (i % 3) == 1
#       node['n'+i.to_s] = to_value
#     elsif (i % 3) == 2
#       node['n'+i.to_s] = cc_value
#     else
#       node['n'+i.to_s] = bcc_value
#     end
#   end
#   node.save!
# end

def fg_create(model, *args)
  raise 'model can not be nil' if model.nil?
  numargs = args.length
  raise "To many arguments passed to fgcreate: #{numargs}" if numargs > 11
  case numargs
  when 0
    res = FactoryGirl.create(model)
  when 1
    res = FactoryGirl.create(model, args[0])
  when 2
    res = FactoryGirl.create(model, args[0], args[1])
  when 3
    res = FactoryGirl.create(model, args[0], args[1], args[2])
  when 4
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3])
  when 5
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4])
  when 6
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4], args[5])
  when 7
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4], args[5], args[6])
  when 8
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7])
  when 9
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8])
  when 10
    res = FactoryGirl.create(model, args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9])
  end
  return res
end
