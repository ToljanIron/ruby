class UiLevelConfiguration < ActiveRecord::Base
  validate :levels_uniqness
  has_one :company_metric

  def levels_uniqness
    uil = UiLevelConfiguration.where(company_id: company_id, level: level, display_order: display_order, parent_id: parent_id).first
    uilid = uil.nil? ? nil : uil.id
    if id != uilid && !uilid.nil?
      raise 'there is a level same as this one' + company_id.to_s + " " + level.to_s
    end
  end

  def gauge
    return GaugeConfiguration.find_by_id(gauge_id)
  end

  def find_l4_gauge_decendents
    UiLevelConfiguration.joins('JOIN company_metrics as cm ON cm.id = company_metric_id')
        .joins('JOIN algorithms as al ON cm.algorithm_id = al.id')
        .where(company_id: company_id, parent_id: id)
        .where('al.algorithm_type_id = 5')
  end

  def find_l4_flag_decendents
    UiLevelConfiguration.joins('JOIN company_metrics as cm ON cm.id = company_metric_id')
        .joins('JOIN algorithms as al ON cm.algorithm_id = al.id')
        .where(company_id: company_id, parent_id: id)
        .where('al.algorithm_type_id = 2')
  end

  def find_l4_hidden_flag_decendents
    flags = find_l4_flag_decendents
    return flags.map do |f|
      CompanyMetric.find(f.company_metric_id).algorithm.comparrable_gauge_id
    end
  end

  def find_gauge_decendents
    UiLevelConfiguration.joins('JOIN company_metrics as cm ON cm.id = company_metric_id')
        .joins('JOIN algorithms as al ON cm.algorithm_id = al.id')
        .where(company_id: company_id, parent_id: id)
        .where('al.algorithm_type_id = 6')
  end
end

