require 'csv'
class Company < ActiveRecord::Base

  has_many :groups
  has_many :offices
  has_many :domains
  has_many :network_names
  has_many :company_configuration_tables
  has_many :employees
  has_many :questionnaire_questions
  has_many :questionnaire
  has_many :snapshots
  has_many :alerts
  has_one :push_proc

  has_many :netowrk_snapshot_data

  validates :name, presence: true, length: { maximum: 50 }
  validates_uniqueness_of :name

  scope :domains, ->(id) { Domain.where(company_id: id) }
  scope :employees, ->(cid, sid=nil) {
    sid ||= Snapshot.last_snapshot_of_company(cid)
    Employee.where(company_id: cid, snapshot_id: sid, active: true)
  }

  enum product_type: [:full, :questionnaire_only]

  enum setup_state: [
    :init,
    :log_files_location,
    :log_files_location_verification,
    :gpg_passphrase,
    :it_done,
    :upload_company,
    :standby_or_push,
    :push,
    :push_done,
    :ready
  ]

  def self.required_chars_options
    return ['AB', 'ab', '123', '#$%^&']
  end

  def last_snapshot
    snapshots.order(timestamp: :desc).first
  end

  def list_offices
    return offices.pluck(:name)
  end

  def monitored_user_names
    Company.employees.pluck(:email).map { |e| e.split('@')[0] }
  end

  def export_to_csv
    emails_array = emails
    create_csv [emails_array]
  end

  def emails(sid=nil)
    emails = Company.employees(id, sid).pluck(:email)
    aliases = Employee.aliases(Company.employees(id)).pluck(:email_alias)
    return emails + aliases
  end

  def create_csv(emails_array)
    res = CSV.generate do |csv|
      emails_array.each do |email|
        csv << email
      end
    end
    return res
  end

  def schedule_recovery_job(start_date, end_date, task_name)
    s_t = Time.parse start_date
    e_t = Time.parse end_date
    job = Job.create(
      company_id: id,
      next_run: Time.zone.now,
      name: 'recovery_email_collection',
      reoccurrence: Reoccurrence.create_new_occurrence(10_518_967, 5),
      type_number: Job::CLIENT_JOB
    )
    jtc = JobToApiClientTaskConvertor.create(
      job_id: job.id,
      algorithm_name: 'recovery_email_collection',
      name: 'recovery_email_collection'
    )
    job.update(job_to_api_client_task_convertor_id: jtc.id)
    ConvertionAlgorithmsHelper.recovery_emails_collection(nil, s_t, e_t, name, task_name)
  end

  def active_employees
    Employee.where(company_id: id, active: true).order(:first_name)
  end

  def active_questions
    Question.where(active: true).order(:order)
  end

  def questionnaire_status
    return 0 unless questionnaire && questionnaire.sent
    return 2
  end

  def questionnaire_only?
    product_type == 'questionnaire_only'
  end

  def update_security_settings(session_timeout, password_update_interval, max_login_attempts, required_password_chars)
    update!(session_timeout: session_timeout, password_update_interval: password_update_interval, max_login_attempts: max_login_attempts, required_chars_in_password: required_password_chars)
  end

  def get_required_password_chars
    arr = !required_chars_in_password.nil? ? required_chars_in_password.split('') : '0000'

    res  = []
    Company.required_chars_options.each_with_index {
      |type, i| res.push({text: type, enabled: arr[i] ==='1' ? true : false})
    }
    return res
  end
end
