class CompaniesController < ApiController
  def create

    ActiveRecord::Base.transaction do
      company = Company.new(name: name)
      begin
        company.save!
        domains_arr.each do |d|
          Domain.create(company_id: company.id, domain: d)
        end
        render json: { success: true }
      rescue => e
        puts "EXCEPTION: #{e}"
        puts e.backtrace.join("\n")
        render json: { error: 'Error creating company' }
        raise ActiveRecord::Rollback
      end
    end
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
