# require './app/helpers/import_data_helper.rb'
# include ImportDataHelper

namespace :db do
	task :load_replies, [:qid] => :environment do |t, args|
		qid = args[:qid]
		q = Questionnaire.find(qid)
		path = '/home/giti/replies.xlsx'
		sid = q.snapshot_id
		# ImportDataHelper.load_excel_replies(path,qid,q.snapshot_id)

		ex = Roo::Excelx.new(path)
	    replies_sheet = ex.sheet('Replies')
	    replies = []
	    replies_sheet.each_with_index.map do |xls_line, xls_line_number|
	      if xls_line_number > 0
	        raise "Error: Missing value in line #{xls_line_number}" if (xls_line[0].blank? || xls_line[1].blank? || xls_line[2].blank?)
	        rep = {
	          question_id: xls_line[0],
	          from: xls_line[1].to_s.strip,
	          to: xls_line[2].to_s.strip#, answer: xls_line[3]
	        }
	        replies << rep
	      end
	    end
	    participants = {}
	    result = QuestionnaireQuestion.find_by_sql("select qp.id as qp_id, e.external_id from questionnaire_participants qp inner join employees e on e.id= qp.employee_id and e.snapshot_id=#{sid}")
	    result.each do |row|
	      participants[row['external_id']] = row['qp_id']
	    end
	    replies.each do |rep|
	      question_reply = QuestionReply.new(questionnaire_id: qid,
	            questionnaire_question_id: rep[:question_id],
	            questionnaire_participant_id: participants[rep[:from]],
	            reffered_questionnaire_participant_id: participants[rep[:to]],
	            answer: true
	            )
	      question_reply.save!
	    end
	end
end
