web: bundle exec passenger start -p $PORT --max-pool-size 2
worker: rake jobs:work
worker: bundle exec sidekiq -c 5
