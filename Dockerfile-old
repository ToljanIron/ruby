FROM spectory/rails-base-image

# Set correct environment variables.
ENV HOME /root

# setup ngnix
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD .specCI/docker_config/nginx.conf /etc/nginx/sites-enabled/webapp.conf

# trick to allow gem installation layer cache
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# create app folder, app should allways be placed under /home/app folder
RUN mkdir /home/app/webapp
ADD . /home/app/webapp
WORKDIR /home/app/webapp

# set up connection to postgres db
ADD .specCI/docker_config/postgres-env.conf /etc/nginx/main.d/postgres-env.conf

# add startup scripts
RUN mkdir -p /etc/my_init.d
ADD .specCI/docker_config/init_db.sh /etc/my_init.d/init_db.sh

# give app user ownership over the app
RUN chown -R app:app /home/app/webapp

# Use baseimage-docker's init process as default runner.
CMD ["/sbin/my_init"]

# Clean up.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*