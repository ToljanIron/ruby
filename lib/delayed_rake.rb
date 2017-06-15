class DelayedRake < Struct.new(:task, :options)
  def perform
    env_options = ''
    options && options.stringify_keys!.each do |key, value|
      env_options << " #{key.upcase}=#{value}"
    end
    puts "Going to run task: #{task}, with options: #{env_options}"
    system("cd #{Rails.root} && RAILS_ENV=#{Rails.env} bundle exec rake #{task} #{env_options} >> /tmp/delayed_job.log")
    puts "Done running task: #{task}"
  end
end
