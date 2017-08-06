class JobTitle < ActiveRecord::Base
  has_many :employees
  belongs_to :color
  validates :name, presence: true, length: { maximum: 500 }

  def pack_to_json
    h = {}
    h[:name] = name
    h[:color] = color.rgb
    return h
  end
end
