class Algorithm < ActiveRecord::Base
  ## In the underlaying algorithm a good score is indicated by a high value
  SCORE_SKEW_HIGH_IS_GOOD = 1

  ## In the underlaying algorithm a good score is indicated by a low value
  SCORE_SKEW_HIGH_IS_BAD  = 2

  ## In the underlaying algorithm a good score is indicated by a central value (Like faultlines)
  SCORE_SKEW_CENTRAL      = 3

  validates_uniqueness_of :name, :scope => :algorithm_type_id
  has_one :algorithm_flow
  belongs_to :algorithm_type

  enum meaningful_sqew: [:default, :high_is_good, :high_is_bad, :central]

  def run(params_of_function)
    return nil if is_higher_order_gauge?
    return ParamsToArgsHelper.send(name, params_of_function)
  end

  def self.ifGauge(id)
    return Algorithm.find(id).algorithm_type_id == AlgorithmType::GAUGE
  end

  def is_higher_order_gauge?
    return algorithm_type_id == AlgorithmType::HIGHER_LEVEL
  end

  def meaningful_sqew_value
    return SCORE_SKEW_HIGH_IS_GOOD if meaningful_sqew == 'high_is_good'
    return SCORE_SKEW_HIGH_IS_BAD  if meaningful_sqew == 'high_is_bad'
    return SCORE_SKEW_CENTRAL      if meaningful_sqew == 'central'
    return nil
  end

  def self.get_algorithm_id(algorithm)
    if algorithm.is_integer?
      return algorithm.to_i
    else
      CompanyMetric.where(metric_id:  MetricName.where(company_id: 1,name: algorithm).last.id ).last.algorithm_id
    end

  end
end
