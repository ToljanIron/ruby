class BackofficeController < ApiController

  ################### Company #########################

  ## Show all companies
  def show_companies
    render json: Company.all
  end

  ## Create a new company
  def create_company
    name = params[:name]
    if name.nil?
      render json: { error: 'No name given' }
      return
    end
    domains = params[:domains]
    if domains.nil?
      render json: { error: 'No domains given' }
      return
    end
    domains_arr = domains.split(';')
    if domains_arr.empty?
      render json: { error: 'No domain found' }
      return
    end

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
        render json: { error: "Error creating company: #{e.message} " }
        raise ActiveRecord::Rollback
      end
    end
  end

  ################### User #########################

  # Change a user's company
  def change_user_company
    company_name = params[:company_name]
    if company_name.nil?
      render json: { error: 'No company_name given' }
      return
    end
    company = Company.find_by(name: company_name)
    if company.nil?
      render json: { error: 'Company not found' }
      return
    end

    email = params[:email]
    if email.nil?
      render json: { error: 'No email given' }
      return
    end
    user = User.find_by(email: email)
    if user.nil?
      render json: { error: 'User not found' }
      return
    end

    ActiveRecord::Base.transaction do
      begin
        user.update(company_id: company.id)
        render json: { success: true }
      rescue => e
        puts "EXCEPTION: #{e}"
        puts e.backtrace.join("\n")
        render json: { error: "Error creating company: #{e.message} " }
        raise ActiveRecord::Rollback
      end
    end
  end

  ## Show all users
  def show_users
    render json: User.all
  end

  ## Create a new user
  def create_user
    first_name = params[:first_name]
    if first_name.nil?
      render json: { error: 'No first_name given' }
      return
    end

    email = params[:email]
    if email.nil?
      render json: { error: 'No email given' }
      return
    end

    password = params[:password]
    if password.nil?
      render json: { error: 'No password given' }
      return
    end

    company_name = params[:company_name]
    if company_name.nil?
      render json: { error: 'No company_name given' }
      return
    end
    company = Company.find_by(name: company_name)
    if company.nil?
      render json: { error: 'Company not found' }
      return
    end

    ActiveRecord::Base.transaction do
      begin
        User.create!(
          first_name: first_name,
          email: email,
          password: password,
          company_id: company.id,
          role: 1
        )
        render json: { success: true }
      rescue => e
        puts "EXCEPTION: #{e}"
        puts e.backtrace.join("\n")
        render json: { error: "Error creating company: #{e.message} " }
        raise ActiveRecord::Rollback
      end
    end
  end
end
