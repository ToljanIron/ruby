class OverlayEntityType < ActiveRecord::Base
  has_many :overlay_entities
  has_many :overlay_entity_groups
  belongs_to :color
  enum overlay_entity_type: [:external_domain, :keyword]

  def as_json(options = {})
    super(options).merge(color: color[:rgb])
  end
end
