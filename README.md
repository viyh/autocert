# [Autocert](https://github.com/viyh/autocert) #

Docker image to create SSL certs with Let's Encrypt Certbot. This is meant to be used for SSL cert automation and also has the ability to add certificates to a Java keystore. This uses the new "certbot" tool, not the legacy "letsencrypt-auto" tool.

## Usage ##

### Create certificate ###

        docker run -it --rm --name autocert \
            -p 80:80 -p 443:443 \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-create \
                --domains "test.uberboxen.net test1.uberboxen.net test2.uberboxen.net" \
                --email "admin@uberboxen.net"

    --domains (required) - Space-separated list of domains to add to the SSL
        certificate. *All domains that are being added to the cert must resolve
        to the host wher this container is running.

    --email (optional) - Email address for the administrator on the SSL
        certificate. By default, the first domain in CERT_DOMAINS will be used.

### Renew certificate ###

        docker run -it --rm --name autocert \
            -p 80:80 -p 443:443 \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-renew

### Show ###

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-show <DOMAIN> <TYPE>

    DOMAIN (required) - The domain of the key/cert/chain to show.

    TYPE (required) - One of: key, cert, chain, fullchain

#### Show a key ####

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-show test.uberboxen.net key

#### Show a cert ####

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-show test.uberboxen.net cert

#### Show a chain cert ####

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-show test.uberboxen.net chain

#### Show a full chain certs ####

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            viyh/autocert \
            autocert-show test.uberboxen.net fullchain

### Add key/cert to Java keystore ###

Mount the keystore that you want to add/update to /keystore.

        docker run -it --rm --name autocert \
            -v autocert-conf:/etc/letsencrypt \
            -v /path/to/keystore:/keystore \
            viyh/autocert \
            autocert-update-java-keystore \
                --domain ntp.disconformity.net \
                --alias cert_alias \
                --passphrase changeit

    --domain (required) - The domain of the key/cert to add/update in the keystore.

    --alias (optional) - The alias of the key/cert in the keystore. By default, this
        will be the domain name.

    --passphrase (optional) - The keystore password. If this is not default ("changeit")
        then this will need to be specified.
