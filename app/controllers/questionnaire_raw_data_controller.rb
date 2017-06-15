class QuestionnaireRawDataController < ApplicationController

  def import_csv_to_db(csv_file)
    QuestionnaireRawDataHelper.read_csv_to_db(csv_file)
  end
end
