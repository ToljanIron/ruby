class RawDataEntriesController < ApiController
  require 'zip'
  include RawDataEntriesHelper

  def new
  end

  def import_emails
    error = nil
    ActiveRecord::Base.transaction do
      begin
        process_request JSON.parse(request.body.read)
        render json: 'ok', status: 200
      rescue => e
        puts 'import_emails: Error! Failed to process raw-data from client', e.to_s
        error = e.message
        render json: e.to_s, status: 500
        raise ActiveRecord::Rollback
      end
    end
  end
end
