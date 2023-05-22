FROM debian:buster-slim
MAINTAINER Aram Meem
USER root

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
            gcc \
            g++ \
            ca-certificates \
            curl \
            dirmngr \
            fonts-noto-cjk \
            gnupg \
            libssl-dev \
            node-less \
            npm \
            python3-dev \
            libffi-dev \
            libev-dev \
            libevent-dev \
            python3-pip \
            python3-num2words \
            python3-phonenumbers \
            python3-pyldap \
            python3-qrcode \
            python3-renderpm \
            python3-setuptools \
            python3-slugify \
            python3-vobject \
            python3-watchdog \
            python3-xlrd \
            python3-xlwt \
            python3-wheel \
            xz-utils \
            git \
        && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb \
        && echo 'ea8277df4297afc507c61122f3c349af142f31e5 wkhtmltox.deb' | sha1sum -c - \
        && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

RUN apt-get update \
    && apt-get install -y python3-pip \
    && pip3 install --upgrade pip

# install latest postgresql-client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
        && GNUPGHOME="$(mktemp -d)" \
        && export GNUPGHOME \
        && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
        && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
        && gpg --batch --armor --export "${repokey}" > /etc/apt/trusted.gpg.d/pgdg.gpg.asc \
        && gpgconf --kill all \
        && rm -rf "$GNUPGHOME" \
        && apt-get update  \
        && apt-get install --no-install-recommends -y postgresql-client \
        && rm -f /etc/apt/sources.list.d/pgdg.list \
        && rm -rf /var/lib/apt/lists/*

# install rtlcss (on Debian buster)
RUN apt-get update \
    && npm install -g rtlcss

WORKDIR /openupgrade

RUN git clone https://github.com/OCA/OpenUpgrade.git --depth 1 --branch 13.0 --single-branch .

COPY ./openupgrade/extra-addons /extra-addons

RUN pip3 install --use-feature=fast-deps \
    vatnumber==1.2 \
    setuptools wheel \
    git+https://github.com/OCA/openupgradelib.git@master#egg=openupgradelib

# install Odoo requirements
RUN pip3 install -r requirements.txt && pip3 install -r /extra-addons/requirements.txt

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
