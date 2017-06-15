class Configuration < ActiveRecord::Base
  def self.email_average_time
    average = Configuration.where(name: 'email_average_time').first
    return average.value.to_i if average
  end

  def self.number_of_keywords
    keywords_number = Configuration.where(name: 'number_of_keywords').first
    return keywords_number.value.to_i if keywords_number
  end
end
