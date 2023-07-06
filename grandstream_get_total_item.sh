#!/bin/bash
# 
# get GrandStream UCM current calls
# by Jeronimo Zucco 06/07/2023 - jczucco at gmail dot com
# 
# GrandStream API Documentation: https://www.grandstream.com/hubfs/Product_Documentation/UCM_API_Guide.pdf
#
# package dependencies: curl, md5sum, awk, jq (https://jqlang.github.io/jq/)
#
# to use with Zabbix, copy it to /usr/lib/zabbix/externalscripts (debian/ubuntu)

USER='XXXXXX'
PASSWORD='XXXXXX'

# check supported ciphers: https://curl.se/docs/ssl-ciphers.html
# openssl s_client -servername <IP> -connect IP:443
# New, TLSv1.2, Cipher is DHE-RSA-AES256-GCM-SHA384
CURLOPT_SSL_CIPHER_LIST="ECDHE-RSA-NULL-SHA ECDHE-RSA-RC4-SHA ECDHE-RSA-DES-CBC3-SHA ECDHE-RSA-AES128-SHA ECDHE-RSA-AES256-SHA ECDHE-ECDSA-NULL-SHA ECDHE-ECDSA-RC4-SHA ECDHE-ECDSA-DES-CBC3-SHA ECDHE-ECDSA-AES128-SHA ECDHE-ECDSA-AES256-SHA AECDH-NULL-SHA AECDH-RC4-SHA AECDH-DES-CBC3-SHA AECDH-AES128-SHA AECDH-AES256-SHA"
CURL_OPTIONS="-k"
# -k: do not check valid certificate

usage() {
   echo "Uso: $0 <IP GrandStream UCM>"
   exit 2
}
if (( $# != 1 )); then
        usage
fi

URL="https://${1}"

# get CHALLENGE
CHALLENGE=$(curl -s -X POST -H "Content-Type: application/json" -d "{ \"request\":{ \"action\":\"challenge\", \"user\":\"${USER}\", \"version\":\"1.2\" } }" ${CURL_OPTIONS} --ciphers "${CURLOPT_SSL_CIPHER_LIST}" ${URL}/api | grep "\"challenge\":" | cut -d\: -f3 | cut -d\" -f2)
[ "${CHALLENGE}" ] || {
  echo "ERROR retrieving CHALLENGE"
  exit 2
}
DB_PASSWORD=$(echo -n "${CHALLENGE}${PASSWORD}" | md5sum | awk '{ print $1 }')

# get COOKIE LOGIN
COOKIE=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"request\":{ \"action\":\"login\", \"token\":\"${DB_PASSWORD}\", \"url\":\"${URL}\", \"user\":\"cdrapi\" } }" ${CURL_OPTIONS} --ciphers "${CURLOPT_SSL_CIPHER_LIST}" ${URL}/api | grep "\"cookie\":" | cut -d\: -f3 | cut -d\" -f2)
[ "${COOKIE}" ] || {
  echo "ERROR retrieving COOKIE"
  exit 2
}

# GET STATS
curl -s -X POST -H "Content-Type: application/json" -d "{\"request\":{ \"action\":\"listBridgedChannels\", \"cookie\":\"${COOKIE}\" } }" ${CURL_OPTIONS} --ciphers "${CURLOPT_SSL_CIPHER_LIST}" ${URL}/api > /tmp/stats$$.json
#|| { echo "ERROR retrieving STATS"; exit 2 }

TOTAL_ITEM=$(cat /tmp/stats$$.json | jq '..|.total_item?' | grep -v ^null)
echo "${TOTAL_ITEM}"

rm -f /tmp/stats$$.json
