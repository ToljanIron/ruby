class Rank < ActiveRecord::Base
  has_many :employees
  belongs_to :color
  validates :name, presence: true
  validates_uniqueness_of :name

  def pack_to_json
    h = {}
    h[:name] = name
    h[:color] = color.rgb
    return h
  end
end
