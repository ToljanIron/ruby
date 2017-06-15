class CompanyConfigurationTablesController < ApplicationController
  before_action :set_company_configuration_table, only: [:show, :edit, :update, :destroy]

  # GET /company_configuration_tables
  def index
    @company_configuration_tables = CompanyConfigurationTable.all
  end

  # GET /company_configuration_tables/1
  def show
  end

  # GET /company_configuration_tables/new
  def new
    @company_configuration_table = CompanyConfigurationTable.new
  end

  # GET /company_configuration_tables/1/edit
  def edit
  end

  # POST /company_configuration_tables
  def create
    @company_configuration_table = CompanyConfigurationTable.new(company_configuration_table_params)

    if @company_configuration_table.save
      redirect_to @company_configuration_table, notice: 'Company configuration table was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /company_configuration_tables/1
  def update
    if @company_configuration_table.update(company_configuration_table_params)
      redirect_to @company_configuration_table, notice: 'Company configuration table was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /company_configuration_tables/1
  def destroy
    @company_configuration_table.destroy
    redirect_to company_configuration_tables_url, notice: 'Company configuration table was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_company_configuration_table
      @company_configuration_table = CompanyConfigurationTable.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def company_configuration_table_params
      params.require(:company_configuration_table).permit(:key, :value, :comp_id)
    end
end
