
class ReportsController < ApplicationController
  include ExcelHelper

  EMAIL_AIDS = [700, 701, 702, 703, 704, 705, 706, 707]

  def get_emails_excel_report
    authorize :report, :index?

    cid = current_user.company_id

    permitted = params.permit(:gids, :interval, :interval_type)
    gids = permitted[:gids].split(',')
    interval = permitted[:interval]
    interval_type = permitted[:interval_type]

    encryption_key = current_user.document_encryption_password

    report_name = ExcelHelper.create_xls_report_for_emails(
        cid, gids, interval, interval_type, EMAIL_AIDS, encryption_key)

    type = report_name[-3..-1] == 'gpg' ? 'application/pgp-signature' : 'application/vnd.ms-excel'
    send_file(
      "#{Rails.root}/tmp/#{report_name}",
      filename: report_name,
      type: type)
  end
end
