# Debian bookworm contiene python 3.10
FROM debian:bookworm

ENV PIP_ROOT_USER_ACTION=ignore
ENV TZ="Europe/Rome"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ARG DEBIAN_FRONTEND=noninteractive
COPY requirements-docker.txt /root/requirements.txt
RUN apt-get update && apt-get install -y apt-utils && apt-get -y upgrade && apt-get -y full-upgrade && \
apt-get install -y libpq-dev build-essential python3-pandas libgeos-dev zlib1g-dev python3-shapely gunicorn \
                   python3-pip python3-flask python3-sqlalchemy python3-flask-sqlalchemy python3-flask-login \
                   python3-paho-mqtt python3-geoalchemy2 && apt-get autoclean && apt-get clean && \
                   rm -rf /var/lib/apt/lists/* && pip install --upgrade pip && pip install -r /root/requirements.txt

COPY . /root/

WORKDIR /root/

EXPOSE 5000
CMD ["gunicorn","-b","0.0.0.0:5000","--access-logfile","-","project:flask_app"]