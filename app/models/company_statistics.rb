class CompanyStatistics < ActiveRecord::Base
  validates :snapshot_id, presence: true
  belongs_to :snapshot

  # SHORT_LIST_TITLES = ['Volume of Emails Analyzed', 'No. of Employees', 'No. of Completed Questionnaires',
  #                      'Max Advice Providing Indications', 'Max Friendliness Indications'].freeze

  SHORT_LIST_TITLES = ['Volume of Emails Analyzed', 'Avg. No. of Emails to Employee', 'No. of Completed Questionnaires',
                       'Avg. Advice Providing Indications', 'Avg. Friendliness Indications'].freeze

  NEW_NAMES = {
    'Volume of Emails Analyzed': 'No. of Emails Analyzed',
    'Avg. No. of Emails to Employee': 'Avg. Emails per Person',
    'No. of Completed Questionnaires': 'No. of Questionnaires',
    'Avg. Friendliness Indications': 'Avg. friendliness indications',
    'Avg. Advice Providing Indications': 'Avg. Advice indications'
  }.freeze

  # NEW_NAMES = {
  #   'Volume of Emails Analyzed': 'No. of Emails Analyzed',
  #   'No. of Employees': 'Number of Employees',
  #   'No. of Completed Questionnaires': 'No. of Questionnaires',
  #   'Max Advice Providing Indications': 'Max advice indications',
  #   'Max Friendliness Indications': 'Max friendliness indications'
  # }.freeze

  scope :short_list, -> { where(statistic_title: SHORT_LIST_TITLES) }

  def convert_name
    self.statistic_title = NEW_NAMES[self.statistic_title.to_sym] ? NEW_NAMES[self.statistic_title.to_sym] : self.statistic_title
    return self
  end
end
