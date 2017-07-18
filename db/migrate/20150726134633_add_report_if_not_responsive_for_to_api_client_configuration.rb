class AddReportIfNotResponsiveForToApiClientConfiguration < ActiveRecord::Migration[4.2]
  def change
    add_column :api_client_configurations, :report_if_not_responsive_for, :integer
  end
end
