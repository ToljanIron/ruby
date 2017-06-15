class BackofficeController < ApplicationController
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def admin_page
    authorize :application, :admin?
    render 'admin_page', layout: 'v2_application'
  end

  def domains_list
    authorize :application, :admin?
    render 'domains_list', layout: 'v2_application'
  end

  private

  def user_not_authorized
    self.response_body = nil
    redirect_to root_path
  end
end
