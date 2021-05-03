class FactorG < ApplicationRecord
    has_many :employees
    belongs_to :company
end
