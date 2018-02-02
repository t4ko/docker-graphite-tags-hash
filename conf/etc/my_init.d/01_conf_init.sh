#!/bin/bash

conf_dir=/etc/graphite/conf

# auto setup graphite with default configs if /opt/graphite is missing
# needed for the use case when a docker host volume is mounted at an of the following:
#  - /opt/graphite
#  - /opt/graphite/conf
#  - /opt/graphite/webapp/graphite
graphite_dir_contents=$(find /opt/graphite -mindepth 1 -print -quit)
graphite_conf_dir_contents=$(find /opt/graphite/conf -mindepth 1 -print -quit)
graphite_webapp_dir_contents=$(find /opt/graphite/webapp/graphite -mindepth 1 -print -quit)
graphite_storage_dir_contents=$(find /opt/graphite/storage -mindepth 1 -print -quit)
graphite_log_dir_contents=$(find /var/log/graphite -mindepth 1 -print -quit)
graphite_custom_dir_contents=$(find /opt/graphite/webapp/graphite/functions/custom -mindepth 1 -print -quit)
if [[ -z $graphite_log_dir_contents ]]; then
  mkdir -p /var/log/graphite
  chown graphite:graphite /var/log/graphite
  touch /var/log/syslog
fi
if [[ -z $graphite_dir_contents ]]; then
  # git clone -b 1.0.2 --depth 1 https://github.com/graphite-project/graphite-web.git /usr/local/src/graphite-web
  cd /usr/local/src/graphite-web && python ./setup.py install
fi
if [[ -z $graphite_conf_dir_contents ]]; then
  cp -R $conf_dir/opt/graphite/conf/*.conf /opt/graphite/conf/
fi
if [[ -z $graphite_webapp_dir_contents ]]; then
  cp $conf_dir/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
fi
if [[ -z $graphite_storage_dir_contents ]]; then
  /usr/local/bin/django_admin_init.exp
fi
if [[ -z $graphite_custom_dir_contents ]]; then
  touch /opt/graphite/webapp/graphite/functions/custom/__init__.py
fi

