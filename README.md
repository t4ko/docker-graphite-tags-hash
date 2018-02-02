# docker-graphite-tags-hash
Docker image implementing the experimental functionality to use hashs as filename for tagged series
This image is basically a test build of docker-graphite-statsd minus statsd
This repo exists for testing purposes, it was based on docker image and was used as base the "official" Graphite docker image. 


# Docker Image for Graphite

## Get Graphite running instantly

Graphite can be complex to setup.
This image will have you running & collecting stats in just a few minutes.

## Quick Start

```sh
docker run -d\
 --name graphite\
 --restart=always\
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 graphiteapp/graphite-tags-hash
```

This starts a Docker container named: **graphite**

Please also note that you can freely remap container port to any host port in case of corresponding port is already occupied on host. It's also not mandatory to map all ports, map only required ports - please see table below.

That's it, you're done ... almost.



### Includes the following components

* [Nginx](http://nginx.org/) - reverse proxies the graphite dashboard
* [Graphite](http://graphite.readthedocs.org/en/latest/) - front-end dashboard
* [Carbon](http://graphite.readthedocs.org/en/latest/carbon-daemons.html) - back-end

### Mapped Ports

Host | Container | Service
---- | --------- | -------------------------------------------------------------------------------------------------------------------
  80 |        80 | [nginx](https://www.nginx.com/resources/admin-guide/)
2003 |      2003 | [carbon receiver - plaintext](http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-plaintext-protocol)
2004 |      2004 | [carbon receiver - pickle](http://graphite.readthedocs.io/en/latest/feeding-carbon.html#the-pickle-protocol)
2023 |      2023 | [carbon aggregator - plaintext](http://graphite.readthedocs.io/en/latest/carbon-daemons.html#carbon-aggregator-py)
2024 |      2024 | [carbon aggregator - pickle](http://graphite.readthedocs.io/en/latest/carbon-daemons.html#carbon-aggregator-py)
8080 |      8080 | Graphite internal gunicorn port (without Nginx proxying).

Please also note that you can freely remap container port to any host port in case of corresponding port is already occupied on host.

### Mounted Volumes

Host              | Container                  | Notes
----------------- | -------------------------- | -------------------------------
DOCKER ASSIGNED   | /opt/graphite/conf         | graphite config
DOCKER ASSIGNED   | /opt/graphite/storage      | graphite stats storage
DOCKER ASSIGNED   | /opt/graphite/webapp/graphite/functions/custom      | graphite custom functions dir
DOCKER ASSIGNED   | /etc/nginx                 | nginx config
DOCKER ASSIGNED   | /etc/logrotate.d           | logrotate config
DOCKER ASSIGNED   | /var/log                   | log files

### Base Image

Built using [Phusion's base image](https://github.com/phusion/baseimage-docker).

* All Graphite related processes are run as daemons & monitored with [runit](http://smarden.org/runit/).
* Includes additional services such as logrotate.

## Secure the Django Admin

Update the default Django admin user account. _The default is insecure._

  * username: root
  * password: root
  * email: root.graphite@mailinator.com

First login at: [http://localhost/account/login](http://localhost/account/login)
Then update the root user's profile at: [http://localhost/admin/auth/user/1/](http://localhost/admin/auth/user/1/)

## Change the Configuration

Read up on Graphite's [post-install tasks](https://graphite.readthedocs.org/en/latest/install.html#post-install-tasks).
Focus on the [storage-schemas.conf](https://graphite.readthedocs.org/en/latest/config-carbon.html#storage-schemas-conf).

1. Stop the container `docker stop graphite`.
1. Find the configuration files on the host by inspecting the container `docker inspect graphite`.
1. Update the desired config files.
1. Restart the container `docker start graphite`.

**Note**: If you change settings in `/opt/graphite/conf/storage-schemas.conf`
be sure to delete the old whisper files under `/opt/graphite/storage/whisper/`.

---

## A Note on Volumes

You may find it useful to mount explicit volumes so configs & data can be managed from a known location on the host.

Simply specify the desired volumes when starting the container.

```
docker run -d\
 --name graphite\
 --restart=always\
 -v /path/to/graphite/configs:/opt/graphite/conf\
 -v /path/to/graphite/data:/opt/graphite/storage\
 graphiteapp/graphite-tags-hash
```

**Note**: The container will initialize properly if you mount empty volumes at
          `/opt/graphite/conf`, `/opt/graphite/storage`.

## Memcached config

If you have a Memcached server running, and want to Graphite use it, you can do it using environment variables, like this:

```
docker run -d\
 --name graphite\
 --restart=always\
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -e "MEMCACHE_HOST=127.0.0.1:11211"\  # Memcached host. Separate by comma more than one servers.
 -e "CACHE_DURATION=60"\              # in seconds
 graphiteapp/graphite-tags-hash
```

Also, you can specify more than one memcached server, using commas:

```
-e "MEMCACHE_HOST=127.0.0.1:11211,10.0.0.1:11211"
```