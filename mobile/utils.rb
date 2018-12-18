module Mobile::Utils
  def convert_strings_to_keys(hash)
    attrs = {}
    hash.each do |h, v|
      attrs[h.to_sym] = v
    end
    return attrs
  end

  def authenticate_questionnaire_participant(token)
    raise "Null token" unless token
    qp = QuestionnaireParticipant.find_by(token: token)
    return false unless qp
    return qp
  end

  def self.create_employees_connections(json, qp)
    response_emps_ids = json['replies'].map do |r|
      if r['eid'] || r['answer'] == false
        nil
      else
        r['employee_details_id']
      end
    end.compact
    return if response_emps_ids.nil? || response_emps_ids.empty?

    select_query = "select employee_id, connection_id from employees_connections
                    where (employee_id in (#{response_emps_ids.join(',')}) and connection_id = #{qp[:employee_id]})
                    or (employee_id = #{qp[:employee_id]} and connection_id in (#{response_emps_ids.join(',')}))"

    existing_connections = JSON.parse(ActiveRecord::Base.connection.select_all(select_query).to_json)

    values = []
    (response_emps_ids - existing_connections.map { |ec| ec['connection_id'].to_i }).each do |connection_id|
      values << "(#{qp.employee_id}, #{connection_id})"
    end
    (response_emps_ids - existing_connections.map { |ec| ec['employee_id'].to_i }).each do |employee_id|
      values << "(#{employee_id}, #{qp.employee_id})"
    end

    return if values.empty?
    insert_query = "insert into employees_connections (employee_id, connection_id) values #{values.join(',')}"
    ActiveRecord::Base.connection.execute(insert_query)
  end
end
