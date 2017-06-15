class EmployeeEnumeration < ActiveRecord::Base
  def pack_to_json
    {
      id: id,
      company_id: company_id,
      enum_type: enum_type,
      enum_name: enum_name
    }
  end
end
