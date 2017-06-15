if Metric.where(metric_type: 'measure', index: 5).any?
  metric = Metric.where(metric_type: 'measure', index: 5).first
  metric.update_attributes(name: 'Centrality', metric_type: 'measure', index: 5)
end
if Metric.where(metric_type: 'measure', index: 6).any?
  metric = Metric.where(metric_type: 'measure', index: 6).first
  metric.update_attributes(name: 'Central', metric_type: 'measure', index: 6)
end
if Metric.where(metric_type: 'measure', index: 10).any?
  metric = Metric.where(metric_type: 'measure', index: 10).first
  metric.update_attributes(name: 'Politician', metric_type: 'measure', index: 10)
end
if Metric.where(metric_type: 'measure', index: 9).any?
  metric = Metric.where(metric_type: 'measure', index: 9).first
  metric.update_attributes(name: 'In The Loop', metric_type: 'measure', index: 9)
end
if Metric.where(metric_type: 'measure', index: 12).any?
  metric = Metric.where(metric_type: 'measure', index: 12).first
  metric.update_attributes(name: 'Delegator', metric_type: 'measure', index: 12)
end
#  ANALYZE
if Metric.where(metric_type: 'analyze', index: 7).any?
  metric = Metric.where(metric_type: 'analyze', index: 7).first
  metric.update_attributes(name: 'In The Loop', metric_type: 'analyze', index: 7)
end

if Metric.where(metric_type: 'analyze', index: 8).any?
  metric = Metric.where(metric_type: 'analyze', index: 8).first
  metric.update_attributes(name: 'Politician', metric_type: 'analyze', index: 8)
end

if Metric.where(metric_type: 'analyze', index: 5).any?
  metric = Metric.where(metric_type: 'analyze', index: 5).first
  metric.update_attributes(name: 'Centrality', metric_type: 'analyze', index: 5)
end
if Metric.where(metric_type: 'analyze', index: 6).any?
  metric = Metric.where(metric_type: 'analyze', index: 6).first
  metric.update_attributes(name: 'Central', metric_type: 'analyze', index: 6)
end
