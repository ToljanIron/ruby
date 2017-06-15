@c = Company.find_or_create_by!(name: 'QuestComp')

# @q1 = Questionnaire.find_or_create_by!(company_id: @c.id, name: 'Seed Test')
# @q2 = Questionnaire.find_or_create_by!(company_id: @c.id, name: 'Seed Test 2')

@g1 = Group.find_or_create_by!(name: 'questionnair-group', company_id: @c.id)

@e1 = Employee.find_or_create_by!(group_id: @g1.id, email: 'ofer@spectory.com', first_name: 'ofer', last_name: 'l1', company_id: @c.id, external_id: '110')
@e2 = Employee.find_or_create_by!(group_id: @g1.id, email: 'danny@spectory.com', first_name: 'danny', last_name: 'l2', company_id: @c.id, external_id: '111')
@e3 = Employee.find_or_create_by!(group_id: @g1.id, email: 'raz@spectory.com', first_name: 'raz', last_name: 'l3', company_id: @c.id, external_id: '112')
@e4 = Employee.find_or_create_by!(group_id: @g1.id, email: 'guy@spectory.com', first_name: 'guy', last_name: 'l4', company_id: @c.id, external_id: '113')
@e5 = Employee.find_or_create_by!(group_id: @g1.id, email: 'reut@spectory.com', first_name: 'reut', last_name: 'l5', company_id: @c.id, external_id: '114')
@e6 = Employee.find_or_create_by!(group_id: @g1.id, email: 'maria@spectory.com', first_name: 'masha', last_name: 'l6', company_id: @c.id, external_id: '115')

# QuestionnaireParticipant.find_or_create_by!(employee_id: @e1.id, questionnaire_id: @q1.id, token: '1qqqqqq', active: true)
# QuestionnaireParticipant.find_or_create_by!(employee_id: @e2.id, questionnaire_id: @q1.id, token: '2qqqqqq', active: true)
# QuestionnaireParticipant.find_or_create_by!(employee_id: @e3.id, questionnaire_id: @q1.id, token: '3qqqqqq', active: true)
# QuestionnaireParticipant.find_or_create_by!(employee_id: @e4.id, questionnaire_id: @q1.id, token: '4qqqqqq', active: true)

# @qq1 = QuestionnaireQuestion.find_or_create_by!(company_id: @c.id, questionnaire_id: @q1.id, question_id: 1, network_id: 1, title: 'T1', body: 'B1', order: 1, active: 1)
# @qq2 = QuestionnaireQuestion.find_or_create_by!(company_id: @c.id, questionnaire_id: @q1.id, question_id: 2, network_id: 2, title: 'T2', body: 'B2', order: 2, active: 1)
# @qq3 = QuestionnaireQuestion.find_or_create_by!(company_id: @c.id, questionnaire_id: @q1.id, question_id: 3, network_id: 3, title: 'T3', body: 'B3', order: 3, active: 1)
