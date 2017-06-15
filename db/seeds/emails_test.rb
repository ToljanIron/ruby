def msgen
  (0...8).map { (65 + rand(26)).chr }.join
end

RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'reut@spectory.com', to: "{raz@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'reut@spectory.com', to: "{maria@spectory.com}", cc: "{}", bcc: "{raz@spectory.com}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'reut@spectory.com', to: "{danny@spectory.com}", cc: "{}", bcc: "{raz@spectory.com}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'reut@spectory.com', to: "{ofer@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'danny@spectory.com', to: "{reut@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'danny@spectory.com', to: "{ofer@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'raz@spectory.com', to: "{reut@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'raz@spectory.com', to: "{maria@spectory.com}", cc: "{}", bcc: "{}", date: Time.now, fwd: false, processed: false)
RawDataEntry.create!(company_id: 9, msg_id: msgen, from: 'maria@spectory.com', to: "reut@spectory.com{}", cc: "{}", bcc: "{raz@spectory.com}", date: Time.now, fwd: false, processed: false)
