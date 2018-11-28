require 'csv'
require 'zip'
require 'json'

namespace :db do
  desc 'generic_task'
  task :generic_task, [:cid] => :environment do |_t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)

    File.open("./lycored-employee-language.csv", "r").each_line do |line|
      fs = line.split(',')
      lang = fs[1].strip
      emp = Employee.find_by(email: fs[0].downcase, company_id: 23)

      if emp.nil?
        puts "employee: >>>#{fs[0]}<<<, with lang: #{lang} not found"
        next
      end

      language_id = nil
      language_id = 1 if lang.include? 'ENG'
      language_id = 2 if lang.include? 'RUS'
      language_id = 3 if lang.include? 'HEB'

      qp = QuestionnaireParticipant.find_by(employee_id: emp.id)

      if qp.nil?
        puts "did not find questionnaire_participant for employee: #{fs[0]}"
        next
      end

      qp.update!(language_id: language_id)

      puts "update questionnaire_participants set language_id = #{language_id} where employee_id = #{emp.id};"

    end

  end
end

