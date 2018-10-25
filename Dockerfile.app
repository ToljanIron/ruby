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
COPY --chown=app:app templates templates

# Get client side assest
COPY --chown=app:app dist /home/app/html

USER root
RUN /home/app/sa/bin/app_docker_setup.sh
