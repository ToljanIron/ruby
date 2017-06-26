class Pin < ActiveRecord::Base
  has_and_belongs_to_many :employees

  enum status: [:draft, :pre_create_pin, :priority, :in_progress, :saved]

  scope :all_by_company, ->(cid) { Pin.where(company_id: cid) }

  def pack_to_json
    definition = JSON.parse( self.definition.gsub('\"', '"') )
    ui_definition = self.ui_definition.nil? ? nil : JSON.parse( self.ui_definition.gsub('\"', '"') )
    { id: id, company_id: company_id, name: name, definition: definition, status: status, ui_definition: ui_definition }
  end
end
