module ExternalDataHelper
  def get_external_data(company_id)
    res = []
    metric_list = ExternalDataMetric.where(company_id: company_id)
    metric_list.each do |metric|
      data_score_list = ExternalDataScore.where(external_data_metric_id: metric.id)
      next if data_score_list.empty?
      score_to_metric_list = normalized_data data_score_list
      metric_name = metric.external_metric_name
      score_with_snapshot = []
      score_to_metric_list.each do |score_list|
        score_with_snapshot.push(snapshot_id: score_list[:snapshot_id], score: score_list[:score], score_normalize: score_list[:normal_score])
      end
      res.push(id: metric.id,  metric_name: metric_name, score_list: score_with_snapshot)
    end
    return res
  end

  def save_external_data(data_from_server, company_id)
    external_metric_list = data_from_server['external_data_list']
    external_metric_list.each do |current_external_metric|
      metric_name = current_external_metric['metric_name'].to_s
      score_list = current_external_metric['score_list']
      id = current_external_metric['id'].to_i
      metric = ExternalDataMetric.where(id: id, company_id: company_id).first
      unless score_list.empty? && !metric_name.nil?
        if metric
          metric.update_attribute(:external_metric_name, metric_name)
          crate_new_score_list(score_list, metric.id)
        else
          metric = ExternalDataMetric.create(external_metric_name: metric_name, company_id: company_id)
          crate_new_score_list(score_list, metric.id)
        end
      end
    end
    delete_external_metric(data_from_server['remove_list']) if data_from_server['remove_list'].any?
  end

  private

  def normalized_data(score_list)
    max = add_max score_list
    list_to_view = []
    if max == 0
      score_list.each do |o|
        temp = {}
        temp[:snapshot_id] = o[:snapshot_id]
        temp[:score] = o[:score]
        temp[:normal_score] = max.round(2)
        list_to_view.push(temp)
      end
    else
      score_list.each do |o|
        temp = {}
        temp[:snapshot_id] = o.snapshot_id
        temp[:score] = o.score
        temp[:normal_score] = (10 * o.score / max.to_f).round(2)
        list_to_view.push(temp)
      end
    end
    return list_to_view
  end

  def add_max(score_list)
    max = 0
    score_list.each do |unit_score|
      max = unit_score.score if unit_score.score > max
    end
    return max
  end

  def crate_new_score_list(score_list, metric_id)
    ExternalDataScore.where(external_data_metric_id: metric_id).destroy_all
    score_list.each do |score_to_snapshot|
      snapshot_id = score_to_snapshot['snapshot_id'].to_i
      score = score_to_snapshot['score'].to_d.round(2)
      ExternalDataScore.create(external_data_metric_id: metric_id, score: score, snapshot_id: snapshot_id)
    end
  end

  def delete_external_metric(remove_list)
    remove_list.each do |id|
      ExternalDataMetric.where(id: id).destroy_all
      ExternalDataScore.where(external_data_metric_id: id).destroy_all
    end
  end
end
