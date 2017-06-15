# frozen_string_literal: true
class EmployeesConnection < ActiveRecord::Base
  has_many :employees
  has_many :connections
end
