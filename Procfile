web: bundle exec passenger start -p $PORT --max-pool-size 2
#worker: rake jobs:work
#worker: bundle exec sidekiq -c 5
#web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -e production -C config/sidekiq.yml
