class Language < ActiveRecord::Base
  has_many :questionnaires
  enum direction: [:ltr, :rtl]
end
