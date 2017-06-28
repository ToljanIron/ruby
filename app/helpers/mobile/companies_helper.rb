module Mobile::CompaniesHelper
  def load_companies
    @companies = Company.where(active: true).order('id')
  end

  def update_company_by_id(attrs)
    c = Company.find(attrs[:id])
    c.update(attrs) if c
  end

  def create_update_company_by_name(attrs)
    attrs[:active] = true
    Company.create(attrs)
  end

  def diactivate_company_by_id(id)
    c = Company.find(id)
    c.update(active: false)
  end

  def select_company_by_id(id)
    @curr_company = Company.find(id)
    return unless @curr_company
    @curr_employees = Employee.by_company(id).order('first_name')
  end
end
