class GaugeConfiguration < ActiveRecord::Base
  has_one :company_metric, foreign_key: :gauge_id

  def configuration_is_empty?
    self.minimum_value == -1 && self.maximum_value == -1 && self.minimum_area == -1 && self.maximum_area == -1
  end

  def configuration_is_preconfigured?
    !self.static_minimum.nil? && !self.static_maximum.nil?
  end

  def populate(params, company_id)
    self.minimum_value = params[:min_range]
    self.maximum_value = params[:max_range]
    self.minimum_area  = params[:min_range_wanted]
    self.maximum_area  = params[:max_range_wanted]
    self.company_id    = company_id
    save!
  end
end
