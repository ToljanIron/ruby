class RawMeetingsDataController < ApiController
  include RawMeetingsDataHelper

  def new
  end

  def import_meetings
    error = nil
    ActiveRecord::Base.transaction do
      begin
        process_meetings_request JSON.parse(request.body.read)
        render json: 'ok', status: 200
      rescue => e
        puts 'import_meetings: Error! Failed to process raw-meetings-data from client', e.to_s
        error = e.message
        render json: e.to_s, status: 500
        raise ActiveRecord::Rollback
      end
    end
  end
end
