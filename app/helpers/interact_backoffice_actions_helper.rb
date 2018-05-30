require 'twilio-ruby'

module InteractBackofficeActionsHelper

  TIMEOUT = 60 * 60 * 24 * 7

  SMS_TEXT = 'Welcome to StepAhead\'s questionnaire. Please click the link at the bottom the start.'

  EMAIL_SUBJECT = "Welcome to StepAheads survey "
  EMAIL_TEXT = "
    <h1>Hi FIRST_NAME!</h1>
    <p>
    Welcome to StepAhead's survey.
    </p>
    <p>
    We kindly ask you to take a few moments to fill out the survey in <a href=\"LINK\">this link</a>.
    </p>
    <p>
    Your completeion of the quesitonnaire is very important for us and will contribute to the orgainzation's overall success.
    </p>
    <p>
    Thanks for your cooperation.
    </>
  "
  EMAIL_FROM = 'donotreply@mail.2stepahead.com'

  ############################################################
  ## Create a new questionnaire
  ##   - create questionaire
  ##   - create networks
  ##   - copy questions
  ##   - create participants
  ##   - create test participant
  ############################################################
  def self.create_new_questionnaire(cid)

    ## Attached a snapshot to the questionnaire
    snapshot = Snapshot.create_snapshot_by_weeks(cid, Time.now.to_s)
    sid = snapshot.id

    ## Create questionnaire
    quest = Questionnaire.create!(
      company_id: cid,
      state: 0,
      name: "Q-#{cid}-#{Time.now.strftime('%Y%m%d-%M')}",
      language_id: 2,
      sms_text: SMS_TEXT,
      email_text: EMAIL_TEXT,
      email_from: EMAIL_FROM,
      email_subject: EMAIL_SUBJECT,
      test_user_name: 'Test user',
      test_user_email: 'danny@step-ahead.com',
      test_user_phone: '052-6141030',
      snapshot_id: sid
    )

    ## Copy over template qestions
    questions = Question.where(active: true)
    ii = 0
    questions.each do |q|
      ii += 1

      network = NetworkName.find_or_create_by!(
        name: q.title,
        company_id: cid
      )

      QuestionnaireQuestion.create!(
        company_id: cid,
        questionnaire_id: quest.id,
        question_id: q.id,
        network_id: network.id,
        title: q.title,
        body: q.body,
        order: ii * 10,
        min: 1,
        max: 15,
        active: false
      )
    end

    ## Create test participant
    qp = QuestionnaireParticipant.create!(
      employee_id: -1,
      questionnaire_id: quest.id,
      active: true,
      participant_type: 1
    )
    qp.create_token

    return nil
  end

  ################## Send questionnaire ###############################
  def self.send_test_questionnaire(aq)
    qp = QuestionnaireParticipant.where(
      questionnaire_id: aq.id,
      participant_type: 1
    ).last
    qp.reset_questionnaire
    send_test_sms(aq, qp) if aq.delivery_method == 'sms'
    send_test_email(aq, qp) if aq.delivery_method == 'email'
    raise 'Unrecoginzed delivery method' if(aq.delivery_method == 'sms' && aq.delivery_method == 'email')
  end

  def self.send_test_email(aq, qp)
    send_email(
      aq,
      qp,
      aq.test_user_email,
      aq.test_user_name
    )
  end

  def self.send_test_sms(aq, qp)
    send_sms(aq, qp, aq.test_user_phone)
  end

  def self.send_live_questionnaire(aq, qp)
    send_live_sms(aq, qp) if aq.delivery_method == 'sms'
    send_live_email(aq, qp) if aq.delivery_method == 'email'
    raise 'Unrecoginzed delivery method' if(aq.delivery_method == 'sms' && aq.delivery_method == 'email')
  end

  def self.send_live_sms(aq, qp)
    phone = qp.employee.phone_number
    unless phone
      msg = "Not sending to participant: #{qp.id} because phone is nil" if phone.nil?
      puts msg
      EventLog.create!(message: msg, event_type_id: 11)
      return
    end

    phone = phone.gsub('-','')
    is_valid = phone.split('').select { |b| b.match(/\d/) }.join.length == 10
    unless is_valid
      msg = "ERROR - Invalid phone number: #{phone_number} for participant: #{qp.id}"
      puts msg
      EventLog.create!(message: msg, event_type_id: 11)
      return
    end

    send_sms(aq, qp, phone)
  end

  def self.send_live_email(aq, qp)
    puts "qp.employee.email: #{qp.employee.email}"
    puts "qp.employee.first_name: #{qp.employee.first_name}"
    send_email(
      aq,
      qp,
      qp.employee.email,
      qp.employee.first_name
    )
  end

  def self.send_email(aq, qp, email_address, user_name)
    em = ExampleMailer.sample_email(
      email_address,
      aq.email_subject,
      aq.email_from,
      user_name,
      qp.create_link,
      aq.email_text.clone
    )
    em.deliver
  end

  def self.send_sms(aq, qp, phone_number)
    puts "Sending SMS to questionnaire participant: #{qp.id}"
    Dotenv.load if Rails.env.development? || Rails.env.onpremise?
    from        = ENV['TWILIO_FROM_PHONE']
    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token  = ENV['TWILIO_AUTH_TOKEN']
    client = Twilio::REST::Client.new account_sid, auth_token
    sms_text = aq.sms_text
    body = "#{sms_text} #{qp.create_link}"
    client.account.messages.create(
      from: from,
      to:  '+972' + phone_number,
      body: body
    )
  end

########################################################

  ##########################################
  # Run questinonaire:
  #  - Change questionnaire state
  #  - Send notifications to all participants
  ##########################################
  def self.run_questionnaire(aq)
    res = []
    aq.update!(state: :sent)
    res = send_questionnaires(aq)
    return res
  end

  def self.send_questionnaires(aq)
    res = []
    qps = QuestionnaireParticipant
            .where(questionnaire_id: aq.id)
            .where.not(employee_id: -1)
            .where.not(status: 3)
    qps.each do |qp|
      begin
        send_live_questionnaire(aq, qp)
      rescue => ex
        errmsg = "Error while sending to participant: #{qp.employee.id} - #{ex.message}"
        puts errmsg
        puts ex.backtrace
        res << errmsg
      end
    end
  end

  ###########################################
  # Close questionnaire
  ###########################################
  def self.close_questionnaire(aq)
    puts "In close_questionaaire"
    aq.freeze_questionnaire
  end

################## Upload image ########################
  def self.upload_employee_img(img, eid)

    begin
      img_id = img.original_filename[0..-5]
      emp = Employee.find(eid)
      res = check_img_name(img_id, emp, img.original_filename[-3..-1] )
      return res unless res.nil?
      img_url = upload_image(img)

      emp.update!(
        img_url: img_url,
        img_url_last_updated: Time.now
      )
      EventLog.create!(
        message: "Image created for: #{emp.email}",
        event_type_id: 14
      )
    rescue => e
      errmsg = "ERROR loading image: #{e.message}"
      puts errmsg
      puts e.backtrace

      EventLog.create!(
        message: "ERROR emp: #{emp.email}, msg: #{errmsg}",
        event_type_id: 14
      )

      return errmsg
    end
    return nil
  end

  def self.upload_image(img)
    s3_access_key        = ENV['s3_access_key']
    s3_secret_access_key = ENV['s3_secret_access_key']
    s3_bucket_name       = ENV['s3_bucket_name']
    s3_region            = ENV['s3_region']

    Aws.config.update({
      region: s3_region,
      credentials: Aws::Credentials.new(s3_access_key, s3_secret_access_key)
    })

    signer = Aws::S3::Presigner.new
    s3 =     Aws::S3::Resource.new
    bucket = s3.bucket(s3_bucket_name)
    obj = bucket.object(img.original_filename)

    ## Resize the file
    if (File.size(img.path) > 60000)
      res = `convert #{img.path} -resize 220x100 -auto-orient #{img.path}`
      puts res
    end

    ## Upload the file
    obj.upload_file(img.path)

    ## Get a safe url back
    img_url = create_s3_object_url(
            img.original_filename[0..-5],
            signer,
            bucket,
            s3_bucket_name)

    return img_url
  end

  def self.create_s3_object_url(base_name, signer, bucket, bucket_name)
    url = create_url(base_name, 'jpg')
    puts "url: #{url}"
    url = bucket.object(url).exists? ? url : create_url(base_name, 'png')

    if bucket.object(url).exists?
      safe_url = signer.presigned_url(
                   :get_object,
                   bucket: bucket_name,
                   key: url,
                   expires_in: TIMEOUT)
      return safe_url
    else
      raise "Coulnd not find image for #{base_name}.jpg or #{base_name}.png"
    end
  end

  def self.create_url(base_name, image_type)
    return "#{base_name}.#{image_type}"
  end

  def self.check_img_name(img_id, emp, img_suffix)
    if (img_id != emp.email && img_id != emp.phone_number)
      return "Image name does not match participant email or phone number"
    end
    if (img_suffix != 'jpg' && img_suffix != 'png')
      return "Image suffix should be one of: .jpg or .png"
    end
    return nil
  end
############################################################################
end
