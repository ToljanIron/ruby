FactoryGirl.define do
  factory :external_data_metric do
    external_metric_name 'Metric'
    company_id 1
    user_id 10
  end

  factory :external_data_score, class: ExternalDataScore do
    external_data_metric_id 1
    snapshot_id 2
    score 10
  end
end

def create_score(e_data_metric_id, snapshot_id, score)
  FactoryGirl.create(:external_data_score, external_data_metric_id: e_data_metric_id, snapshot_id: snapshot_id, score: score)
end
