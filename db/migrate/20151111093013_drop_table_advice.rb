class DropTableAdvice < ActiveRecord::Migration
  def change
    drop_table :advices
  end
end
