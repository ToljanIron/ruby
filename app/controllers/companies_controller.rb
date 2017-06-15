class CompaniesController < ApplicationController
  def create
    authorize :company, :admin?
    name = params[:data][:name]
    domains = params[:data][:domains]

    ActiveRecord::Base.transaction do
      company = Company.new(name: name)
      begin
        company.save!
        domains.each do |d|
          created_domain = Domain.new(company_id: company.id, domain: d[:name])
          EmailService.create(domain_id: created_domain.id, name: d[:service]) if created_domain.save! && !d[:service].blank?
        end
        redirect_to admin_page_path
      rescue
        render json: { error: 'Error creating company' }
        raise ActiveRecord::Rollback
      end
    end
  end

  def diactivate
    authorize :company, :admin?
    id = params[:id].to_i if params[:id]
    comp = Company.find(id) if id
    comp.update_attribute(:active, false) if comp
    redirect_to admin_page_path
  end

  def update
    authorize :company, :index?
    id = params[:company][:id].to_i if params[:company]
    name = params[:company][:name] if params[:company]
    comp = Company.find(id) if id
    comp.update_attribute(:name, name) if name
    redirect_to admin_page_path
  end
end
