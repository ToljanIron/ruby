class StatisticsDataValuesForCompany < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :company
  has_one :statistics_data_names_for_companies
end
