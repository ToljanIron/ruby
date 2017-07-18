class AddSubjectToRawDataEntries < ActiveRecord::Migration[4.2]
  def up
    add_column :raw_data_entries, :subject, :string, default: nil
  end

  def down
    remove_column :raw_data_entries, :subject
  end
end
