FROM app-base

USER app
WORKDIR /home/app/sa

COPY --chown=app:app bin bin
COPY --chown=app:app config.ru config.ru
COPY --chown=app:app lib lib
COPY --chown=app:app Procfile Procfile
COPY --chown=app:app Rakefile Rakefile
COPY --chown=app:app scripts scripts
COPY --chown=app:app tmp tmp
COPY --chown=app:app VERSION VERSION
COPY --chown=app:app app app
COPY --chown=app:app config config
COPY --chown=app:app db db
COPY --chown=app:app log log
COPY --chown=app:app public public
COPY --chown=app:app vendor vendor

# Precompile assets
RUN bundle exec rake assets:precompile

# Get client side assest
COPY --chown=app:app dist /home/app/html

USER root
RUN rm /etc/nginx/sites-enabled/default
COPY templates/step-ahead.com.conf /etc/nginx/sites-enabled/step-ahead.com.conf

# This file tells ngnix which env vars to retain. The rest will be deleted.
COPY templates/env-vars.conf /etc/nginx/main.d/env-vars.conf

# Handle SSL
COPY templates/step-ahead.com.crt /etc/ssl/certs/step-ahead.com.crt
COPY templates/step-ahead.com.key /etc/ssl/private/step-ahead.com.key

COPY templates/ssl-params.conf.template /etc/nginx/snippets/ssl-params.conf.template
RUN cp /etc/nginx/snippets/ssl-params.conf.template /etc/nginx/snippets/ssl-params.conf

COPY templates/www-data-permissions /etc/sudoers.d/www-data-permissions

# Select ruby
RUN bash -lc 'rvm --default use ruby-2.4.4'

# Sudo
RUN apt-get update
RUN apt-get -y -qq install sudo

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
