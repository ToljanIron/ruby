class AddInteractFieldsToQuestionnaires < ActiveRecord::Migration[4.2]
  def up
    add_column :questionnaires, :delivery_method, :integer, default: 0
    add_column :questionnaires, :email_text, :string
    add_column :questionnaires, :email_from, :string, default: 'donotreply@mail.step-ahead.com'
    add_column :questionnaires, :email_subject, :string, default: 'StepAhead questionnaire'
    add_column :questionnaires, :test_user_name, :string, default: 'Test User'
    add_column :questionnaires, :test_user_phone, :string, default: '052-6141030'
    add_column :questionnaires, :test_user_email, :string, default: 'danny@step-ahead.com'
  end

  def down
    remove_column :questionnaires, :delivery_method
    remove_column :questionnaires, :email_text
    remove_column :questionnaires, :email_from
    remove_column :questionnaires, :email_subject
    remove_column :questionnaires, :test_user_name
    remove_column :questionnaires, :test_user_phone
    remove_column :questionnaires, :test_user_email
  end
end
