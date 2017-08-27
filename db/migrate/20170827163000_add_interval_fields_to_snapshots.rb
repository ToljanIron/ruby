class AddIntervalFieldsToSnapshots < ActiveRecord::Migration[4.2]
  def up
    add_column :snapshots, :month,     :string
    add_column :snapshots, :quarter,   :string
    add_column :snapshots, :half_year, :string
    add_column :snapshots, :year,      :string
    populate_all_snapshots
  end

  def down
    remove_column :snapshots, :month
    remove_column :snapshots, :quarter
    remove_column :snapshots, :half_year
    remove_column :snapshots, :year
  end

  def populate_all_snapshots
    Snapshot.all.each do |s|
      puts "Working on snapshot: #{s.id}"
      s.update!(month: s.get_month)
      s.update!(quarter: s.get_quarter)
      s.update!(half_year: s.get_half_year)
      s.update!(year: s.get_year)
    end
  end

end
