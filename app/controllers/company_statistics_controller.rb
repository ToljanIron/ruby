class CompanyStatisticsController < ApplicationController
  def get_company_statistics
    authorize :employee, :index?
    res = []
    snapshot_id = params['sid'] || Snapshot.where(company_id: current_user.company_id, snapshot_type: nil, status: Snapshot::STATUS_ACTIVE).order('timestamp ASC').last.id
    if Snapshot.find(snapshot_id).company_id != current_user.company_id
      render json: { msg: "#{snapshot_id} != current user company" }
      return
    end
    relevant_company_statistics = CompanyStatistics.where(snapshot_id: snapshot_id).short_list
    if relevant_company_statistics.count <= 0
      render json: { msg: "there is no company statistics for snapshot #{snapshot_id}" }
      return
    end
    relevant_company_statistics.take(3).each do |company_statistic|
      res.push(company_statistic.convert_name)
    end
    last_q = Questionnaire.where(company_id: Snapshot.find(snapshot_id).company_id).order('created_at desc').first
    if last_q
      total = last_q.questionnaire_participant.where(active: true).count
      if total != 0
        completed = (last_q.questionnaire_participant.where(status: 3, active: true).count.to_f / total).round(2) * 100
        completed = completed.to_f.round(2).strip.to_s + '%'
      else
        completed = 'N/A'
      end
    else
      completed = 'N/A'
    end
    res.push(statistic_title: 'Questionnaire Response Rate', statistic_data: completed)
    relevant_company_statistics.reverse.take(2).each do |company_statistic|
      res.push(company_statistic.convert_name)
    end
    render json: { company_statistics: res }
  end
end
