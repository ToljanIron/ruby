class FactorC < ApplicationRecord
    has_many :employees
    belongs_to :company
end
