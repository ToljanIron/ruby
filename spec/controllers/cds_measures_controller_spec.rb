require 'spec_helper'
require './spec/spec_factory'
require 'rake'
require './spec/factories/company_with_metrics_factory.rb'
include CompanyWithMetricsFactory

describe MeasuresController, type: :controller do
end
