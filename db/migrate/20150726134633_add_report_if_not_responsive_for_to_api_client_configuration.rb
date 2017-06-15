class AddReportIfNotResponsiveForToApiClientConfiguration < ActiveRecord::Migration
  def change
    add_column :api_client_configurations, :report_if_not_responsive_for, :integer
  end
end
