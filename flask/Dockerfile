FROM debian:bookworm

ENV PIP_ROOT_USER_ACTION=ignore
ENV TZ="Europe/Rome"

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get -y upgrade && apt-get -y full-upgrade
#        apt-get install -y --no-install-recommends \
#        python3.10 libpython3.10-dev python3.10-venv python3-pip gunicorn && \
#    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 0 && \
#    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 0
RUN apt-get install -y libpq-dev build-essential python3-pandas libgeos-dev zlib1g-dev python3-shapely gunicorn
RUN apt-get install -y python3-pip
RUN apt-get install -y python3-flask python3-sqlalchemy python3-flask-sqlalchemy python3-flask-login
RUN apt-get install -y python3-paho-mqtt python3-geoalchemy2
RUN pip freeze
RUN rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip

COPY requirements-docker.txt /root/requirements.txt
RUN pip install -r /root/requirements.txt

COPY . /root/

WORKDIR /root/


EXPOSE 5000

CMD ["gunicorn","-b","0.0.0.0:5000","--access-logfile","-","project:flask_app"]