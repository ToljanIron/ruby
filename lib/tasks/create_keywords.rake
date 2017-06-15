namespace :db do
  require './app/helpers/key_words_helper.rb'
  include KeyWordsHelper

  desc 'create_keywords'
  task :create_keywords, [:company_id, :sid, :rewrite] => :environment do |t, args|
    config = ActiveRecord::Base.configurations[Rails.env || 'development'] || ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection(config)
    company_id = args[:company_id]
    snapshot_id = args[:sid].try(:to_i)
    rewrite = args[:rewrite] || false
    raise '**** company id is empty *******' unless company_id
    ActiveRecord::Base.transaction do
      begin

        if rewrite == true.to_s
          Snapshot.where(company_id: company_id, status: Snapshot::STATUS_ACTIVE).each { |s| KeyWordsHelper.create_key_words(s.id) }
        else
          if snapshot_id == -1
            sid = Snapshot.select(:id).order(:timestamp).last.id
          else
            sid = snapshot_id
          end
          KeyWordsHelper.create_key_words(sid)
        end

      rescue => e
        puts e
        raise ActiveRecord::Rollback
      end
    end
  end
end
