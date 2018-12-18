module Mobile::AnswersVerifierHelper
require 'csv'

  def self.verify_amount_of_true(num_of_true, path)
    sum = 0
    lines = 1
    CSV.foreach(path) do |row|
      ap lines
      row.each do |value|
        sum = sum + 1 if !value.nil? && value.downcase == 'true'
      end
      lines = lines + 1
    end
    ap sum
    QuestionReply.update_all(answer: nil)
    return sum == num_of_true
  end


  def self.mock_answers(amount_to_mock)
    # question_relplies = []
    question_relplies = AnswersVerifierHelper.get_question_reply_with_no_answer(amount_to_mock)
    question_relplies.update_all(answer: true)
  end

  def self.get_question_reply_with_no_answer(amount_to_mock)
    qr = QuestionReply.order("RANDOM()").limit(amount_to_mock)
    return qr
  end

    def self.check_if_there_is_emp_to_himself
      count = 0
      QuestionReply.all.each do |qr| 
        count = count + 1 if qr.employee_id == qr.reffered_employee_id
      end
      ap count
    end
end