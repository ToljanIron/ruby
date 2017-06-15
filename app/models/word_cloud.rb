class WordCloud < ActiveRecord::Base
  belongs_to :company
  belongs_to :group
  belongs_to :snapshot
end
