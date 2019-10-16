class CompaniesController < ApiController
  def update
    authorize :company, :index?
    id = params[:company][:id].to_i if params[:company]
    name = params[:company][:name] if params[:company]
    comp = Company.find(id) if id
    comp.update_attribute(:name, name) if name
    redirect_to admin_page_path
  end
end
