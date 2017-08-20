class AddDocumentEncryptionPasswordUsersTable < ActiveRecord::Migration[5.1]
  def change
  	add_column :users, :document_encryption_password, :string unless column_exists? :users, :document_encryption_password
  end
end
