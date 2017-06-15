# class EmailSnapshotData < ActiveRecord::Base
#   belongs_to :employee_from,   class_name: 'Employee', foreign_key: 'employee_from_id'
#   belongs_to :employee_to,   class_name: 'Employee', foreign_key: 'employee_to_id'
#   validates :employee_from_id, presence: true
#   validates :employee_to_id, presence: true
#   enum significant_level: { not_significant: 1, sporadic: 2, meaningfull: 3 }
#   enum above_median: { below: 0, above: 1 }

#   def not_empty_emails?
#     (1..18).each do |i|
#       return true if self["n#{i}".to_sym] != 0
#     end
#     return false
#   end

#   def calc_n1_to_n18
#     return n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8 + n9 + n10 + n11 +
#            n12 + n13 + n14 + n15 + n16 + n17 + n18
#   end
# end
# ASAF BYEBUG DEAD CODE