#!/bin/bash
#
# The MIT License
#
# Copyright 2013-2015 Jakub Jirutka <jakub@jirutka.cz>.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# -----BEGIN HELP-----
# Import pair of certificate and key in PEM format into a Java keystore.
#
# Usage:
#   @SCRIPT_NAME@ -s KEYSTORE -k KEYFILE -c CERTFILE -a ALIAS [options]
#
# Options:
#   -s KEYSTORE --keystore KEYSTORE    Keystore to import certificate to (required).
#   -k KEYFILE --key KEYFILE           Private key file in PEM format to import (required).
#   -c CERTFILE --cert CERTFILE        Certificate file in PEM format to import (required).
#   -a ALIAS --alias ALIAS             Unique alias of the certificate (required).
#   -p PASS --passphrase PASS          Passphrase of the keystore (read from stdin if not specified).
#   -i CERTFILE --cert-chain CERTFILE  File with intermediate certificates in PEM format (optional).
#   -h --help                          Show this message.
#
# -----END HELP-----
set -e

SCRIPT_NAME="$(basename $0)"
temp_dir=


#======================  Functions  ======================#

# Prints message and exits.
die() {
    echo -e "${SCRIPT_NAME}: $1" >&2
    exit ${2:-2}
}

# Cleans temp directory.
cleanup() {
    if [[ -n "$temp_dir" && -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
    fi
}

# Prints usage help.
usage() {
    cat "$0" \
        | sed -En '/-{5}BEGIN HELP-{5}/,/-{5}END HELP-{5}/p' \
        | sed -E "s/^# ?//; 1d;\$d; s/@SCRIPT_NAME@/${SCRIPT_NAME}/"
}


#=========================  Main  ========================#

keystore=
key=
cert=
cert_alias=
passphrase=
int_cert=

while [ $# -gt 0 ]; do
    case $1
    in
        -s | --keystore)
            keystore=$2
            shift 2
    ;;
        -k | --key)
            key=$2
            shift 2
    ;;
        -c | --cert)
            cert=$2
            shift 2
    ;;
        -a | --alias)
            cert_alias=$2
            shift 2
    ;;
        -p | --passphrase)
            passphrase=$2
            shift 2
    ;;
        -i | --cert-chain)
            int_cert=$2
            shift 2
    ;;
        -h | --help)
            usage
            exit 0
    ;;
        *)
            die "Unknown option $1"
    ;;
    esac
done

if [[ -z "$key" || -z "$cert" || -z "$cert_alias" ]]; then
    usage
    exit 1
fi

for file in "$key" "$cert"; do
    if [[ -n "$file" && ! -f "$file" ]]; then
        die "File $file does not exist"
    fi
done

if [ ! -f "$keystore" ]; then
    storedir=$(dirname "$keystore")
    if [[ ! -d "$storedir" || ! -w "$storedir" ]]; then
        die "Directory $storedir does not exist or is not writable"
    fi
fi

if [ -z "$passphrase" ]; then
    read -p 'Enter a passphrase: ' -s passphrase
    echo ''
fi


temp_dir=$(mktemp -q -d /tmp/${SCRIPT_NAME}.XXXXXX)
trap cleanup EXIT
trap '{ cleanup; exit 127; }' INT TERM

pkcs12="${temp_dir}/pkcs12"

# bundle cert and key in PKCS12
openssl pkcs12 \
    -export \
    -in "$cert" \
    -inkey "$key" \
    -out "$pkcs12" \
    -password "pass:${passphrase}" \
    -name "$cert_alias" \
    ${int_cert:+-certfile "$int_cert"}

# print cert
echo -n "Importing \"$cert_alias\" with "
openssl x509 -noout -fingerprint -in "$cert"

# import PKCS12 to keystore
keytool \
    -noprompt \
    -importkeystore \
    -deststorepass "$passphrase" \
    -destkeystore "$keystore" \
    -srckeystore "$pkcs12" \
    -srcstoretype 'PKCS12' \
    -srcstorepass "$passphrase"
