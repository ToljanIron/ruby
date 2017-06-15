class ApiClientTaskDefinition < ActiveRecord::Base
  belongs_to  :job_queue

  validates :name, presence: true
  validates :script_path, presence: true

  def self.create_by_name_and_script_path(name, script_path)
    return nil unless name
    return nil unless script_path
    res = ApiClientTaskDefinition.create(name: name, script_path: script_path)
    return res
  end
end
