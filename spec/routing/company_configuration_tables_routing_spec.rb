require "spec_helper"

RSpec.describe CompanyConfigurationTablesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/company_configuration_tables").to route_to("company_configuration_tables#index")
    end

    it "routes to #new" do
      expect(:get => "/company_configuration_tables/new").to route_to("company_configuration_tables#new")
    end

    it "routes to #show" do
      expect(:get => "/company_configuration_tables/1").to route_to("company_configuration_tables#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/company_configuration_tables/1/edit").to route_to("company_configuration_tables#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/company_configuration_tables").to route_to("company_configuration_tables#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/company_configuration_tables/1").to route_to("company_configuration_tables#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/company_configuration_tables/1").to route_to("company_configuration_tables#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/company_configuration_tables/1").to route_to("company_configuration_tables#destroy", :id => "1")
    end

  end
end
