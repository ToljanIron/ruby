# frozen_string_literal: true
class PushProc < ActiveRecord::Base

  belongs_to :company

  enum state: [
    :init,
    :transfer_log_files,
    :process_log_files,
    :collector_done,
    :count_snapshots,
    :create_snapshots,
    :preprocess_snapshots,
    :done,
    :error
  ]

end
