# frozen_string_literal: true
require 'tempfile'
require './app/helpers/util_helper.rb'

module Mobile::EmployeesHelper
  def deactivate_employee_by_id(id, questionnaire_id)
    QuestionnaireParticipant.set_active_employees(questionnaire_id, [id])
  end

  def upload_img(img, e)
    e.update(img_token: "mobile-#{e.email}")
    file_name = e[:img_token] + File.extname(img.original_filename)
    file = Tempfile.new(file_name, encoding: 'ascii-8bit')
    file.write(img.read)
    path = file.path
    bucket_name = 'workships'
    s3 = AWS::S3.new(access_key_id: ENV['s3_access_key'], secret_access_key: ENV['s3_secret_access_key'])
    key = file_name
    s3.buckets[bucket_name].objects[key].write(file: path)
    file.close
    file.unlink
    e.check_img_url
  rescue StandardError => e
    ap "upload_to_s3: Faild to upload #{key}"
    raise e
  end

  def hash_employees_of_company_by_token(token)
    qp_ids = QuestionnaireParticipant.find_by(token: token).questionnaire.questionnaire_participant.pluck(:id)
    return if qp_ids.nil? || qp_ids.empty?
    query = "select emp.id as id,
            (#{UtilHelper.sql_concat('emp.first_name', 'emp.last_name')}) as name,
            emp.img_url as image_url,
            roles.name as role,
            qp.id as qp_id
            from employees as emp
            left join questionnaire_participants as qp on qp.employee_id = emp.id
            left join roles on emp.role_id = roles.id
            where qp.id in (#{qp_ids.join(',')})"
    res = ActiveRecord::Base.connection.select_all(query)
    res = res.to_json
    return res
  end
end
