class Reoccurrence < ActiveRecord::Base
  validates :run_every_by_minutes, presence: true
  validates :fail_after_by_minutes, presence: true

  MONTH_MINUTES = 43_829
  WEEK_MINUTES = 10_080
  DAY_MINUTES = 1440
  HOUR_MINUTES = 60

  def self.create_new_occurrence(run_every_minutes, fail_after_minutes, name = nil)
    Reoccurrence.create(run_every_by_minutes: run_every_minutes, fail_after_by_minutes: fail_after_minutes, name: name)
  end

  def self.monthly
    MONTH_MINUTES
  end

  def self.weekly
    WEEK_MINUTES
  end

  def self.daily
    DAY_MINUTES
  end

  def self.hourly
    HOUR_MINUTES
  end
end
