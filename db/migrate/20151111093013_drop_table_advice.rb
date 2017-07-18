class DropTableAdvice < ActiveRecord::Migration[4.2]
  def change
    drop_table :advices
  end
end
