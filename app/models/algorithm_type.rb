class AlgorithmType < ActiveRecord::Base
  GAUGE        = 5
  HIGHER_LEVEL = 6
  WORDCLOUD    = 7

  has_one :algorithm
end
