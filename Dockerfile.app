FROM app-base

USER app
WORKDIR /home/app/sa

COPY --chown=app:app bin bin
RUN chmod -R 700 bin
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

# Get client side assest
COPY --chown=app:app dist /home/app/html

USER root
COPY templates/step-ahead.com.crt /etc/ssl/certs/step-ahead.com.crt
COPY templates/step-ahead.com.key /etc/ssl/private/step-ahead.com.key
COPY templates/sa-nginx.conf.ssltemplate /etc/nginx/sites-available/sa-nginx.conf.ssltemplate
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /etc/nginx/sites-available/sa-nginx.conf.ssltemplate /etc/nginx/sites-enabled/step-ahead.com.conf
COPY templates/ssl-params.conf.template /etc/nginx/snippets/ssl-params.conf.template
RUN cp /etc/nginx/snippets/ssl-params.conf.template /etc/nginx/snippets/ssl-params.conf

# This file tells ngnix which env vars to retain. The rest are deleted.
COPY templates/env-vars.conf /etc/nginx/main.d/env-vars.conf

COPY templates/app-user-permissions /etc/sudoers.d/app-user-permissions

# Handle SSH to host
COPY templates/authorized_keys_app /root/.ssh/authorized_keys
COPY templates/ssh_config /etc/ssh/ssh_config
COPY templates/sshd_config /etc/ssh/sshd_config

# Select ruby
RUN bash -lc 'rvm --default use ruby-2.4.4'

# Run this script before container startup
RUN mkdir -p /etc/my_init.d
COPY scripts/docker_entrypoint.sh /etc/my_init.d
