FROM phusion/baseimage:0.9.22

RUN apt-get -y update \
  && apt-get -y upgrade \
  && apt-get -y install vim \
  nginx \
  python-dev \
  python-flup \
  python-pip \
  python-ldap \
  expect \
  git \
  memcached \
  sqlite3 \
  libffi-dev \
  libcairo2 \
  libcairo2-dev \
  python-cairo \
  python-rrdtool \
  pkg-config \
  nodejs \
  && rm -rf /var/lib/apt/lists/*

# choose a timezone at build-time
# use `--build-arg CONTAINER_TIMEZONE=Europe/Brussels` in `docker build`
ARG CONTAINER_TIMEZONE
ENV DEBIAN_FRONTEND noninteractive

RUN if [ ! -z "${CONTAINER_TIMEZONE}" ]; \
    then ln -sf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata; \
    fi

# fix python dependencies (LTS Django)
RUN pip install --upgrade pip && \
  pip install django==1.8.18

ARG version=1.1.1
ARG whisper_version=${version}
ARG carbon_version=tag-hash-files
ARG graphite_version=tag-hash-files

ARG whisper_repo=https://github.com/graphite-project/whisper.git
ARG carbon_repo=https://github.com/DanCech/carbon.git
ARG graphite_repo=https://github.com/DanCech/graphite-web.git

# install whisper
RUN git clone -b ${whisper_version} --depth 1 ${whisper_repo} /usr/local/src/whisper
WORKDIR /usr/local/src/whisper
RUN python ./setup.py install

# install carbon
RUN git clone -b ${carbon_version} --depth 1 ${carbon_repo} /usr/local/src/carbon
WORKDIR /usr/local/src/carbon
RUN pip install -r requirements.txt \
  && python ./setup.py install

# install graphite
RUN git clone -b ${graphite_version} --depth 1 ${graphite_repo} /usr/local/src/graphite-web
WORKDIR /usr/local/src/graphite-web
RUN pip install -r requirements.txt \
  && python ./setup.py install

# config graphite
ADD conf/opt/graphite/conf/*.conf /opt/graphite/conf/
ADD conf/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
# ADD conf/opt/graphite/webapp/graphite/app_settings.py /opt/graphite/webapp/graphite/app_settings.py
WORKDIR /opt/graphite/webapp
RUN mkdir -p /var/log/graphite/ \
  && PYTHONPATH=/opt/graphite/webapp django-admin.py collectstatic --noinput --settings=graphite.settings

# config nginx
RUN rm /etc/nginx/sites-enabled/default
ADD conf/etc/nginx/nginx.conf /etc/nginx/nginx.conf
ADD conf/etc/nginx/sites-enabled/graphite-tags-hash.conf /etc/nginx/sites-enabled/graphite-tags-hash.conf

# init django admin
ADD conf/usr/local/bin/django_admin_init.exp /usr/local/bin/django_admin_init.exp
ADD conf/usr/local/bin/manage.sh /usr/local/bin/manage.sh
RUN chmod +x /usr/local/bin/manage.sh && chmod +x /usr/local/bin/django_admin_init.exp \
  && ls -l /usr/local/bin/ && /usr/local/bin/django_admin_init.exp

# logging support
RUN mkdir -p /var/log/carbon /var/log/graphite /var/log/nginx
ADD conf/etc/logrotate.d/graphite-tags-hash /etc/logrotate.d/graphite-tags-hash

# daemons
ADD conf/etc/service/carbon/run /etc/service/carbon/run
ADD conf/etc/service/carbon-aggregator/run /etc/service/carbon-aggregator/run
ADD conf/etc/service/graphite/run /etc/service/graphite/run
ADD conf/etc/service/nginx/run /etc/service/nginx/run
RUN chmod -R +x /etc/service/

# default conf setup
ADD conf /etc/graphite-tags-hash/conf
ADD conf/etc/my_init.d/01_conf_init.sh /etc/my_init.d/01_conf_init.sh

# cleanup
RUN apt-get clean\
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# defaults
EXPOSE 80 2003-2004 2023-2024 8080
VOLUME ["/opt/graphite/conf", "/opt/graphite/storage", "/opt/graphite/webapp/graphite/functions/custom", "/etc/nginx", "/etc/logrotate.d", "/var/log"]
WORKDIR /
ENV HOME /root

CMD ["/sbin/my_init"]