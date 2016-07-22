FROM python:3.4-alpine

RUN mkdir -p /certbot \
    && apk add --update --no-cache \
        openjdk8-jre-base \
        openssl \
        py-setuptools \
        py-virtualenv \
        nginx \
        bash \
        gettext \
        certbot \
    && rm -rf /etc/nginx/*.default \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

WORKDIR /certbot

ADD create /usr/local/bin/autocert-create
RUN chmod +x /usr/local/bin/autocert-create
ADD renew /usr/local/bin/autocert-renew
RUN chmod +x /usr/local/bin/autocert-renew
ADD show /usr/local/bin/autocert-show
RUN chmod +x /usr/local/bin/autocert-show
ADD keytool-import.sh /usr/local/bin/keytool-import.sh
RUN chmod +x /usr/local/bin/keytool-import.sh
ADD update-java-keystore /usr/local/bin/autocert-update-java-keystore
RUN chmod +x /usr/local/bin/autocert-update-java-keystore

EXPOSE 80
EXPOSE 443

CMD autocert-create
