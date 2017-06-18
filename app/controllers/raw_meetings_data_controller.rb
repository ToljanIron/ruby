include RawMeetingsDataHelper

class RawMeetingsDataController < ApiController

  def new
  end
  
  def import_meetings
    ActiveRecord::Base.transaction do
      begin
        process_meetings_request JSON.parse(request.body.read)
        render json: 'ok', status: 200
      rescue => e
        puts 'import_meetings: Error! Failed to process raw-meetings-data from client'
        message = e.message[0...1000]
        puts message
        puts e.backtrace.join("\n")
        render json: message, status: 500
        raise ActiveRecord::Rollback
      end
    end
  end
end
