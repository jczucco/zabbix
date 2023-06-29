#!/bin/bash

# Simple script to get some PaloAlto firewall performance counters not avalialable by SNMP
# 
# by Jeronimo Zucco <jczucco at gmail.com>
#
# Instructions:
# 1 - Go to PaloAlto Device → Admin Roles → Add. 
#   - create a XML API role with Operational Requests
#	2 - Go to Device → Administrators → Add.
#   - create a Role based user with the profile role associated 
# 3	- Get the API XML Key in browser: 
#   - https://URLPALOALTO/api/?type=keygen&user=username&password=password

usage() {
   echo "Syntax: $0 <arptable|ipv6neighbor|session|sessions|totalfwtablesize|ipv4fwtablesize|ipv6fwtablesize>"
   exit 2
}

if (( $# != 1 )); then
  usage
  exit 2
fi

PARAMETER=$(echo $1 | tr '[:upper:]' '[:lower:]')
URLPALOALTO="https://X.X.X.X"
APIKEY="YOURAPIKEYHERE"

case ${PARAMETER} in
  arptable)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=%3Cshow%3E%3Carp%3E%3Centry%20name%20%3D%20%27all%27%2F%3E%3C%2Farp%3E%3C%2Fshow%3E" | grep total | cut -d\> -f2 | cut -d\< -f1
    ;;
  ipv6neighbor)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=<show><neighbor><interface></interface></neighbor></show>" | grep "<total>" | cut -d\> -f2 | cut -d\< -f1
    ;;
  session|sessions)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=<show><resource><limit><session/></limit></resource></show>" | grep num-active | cut -d\> -f2 | cut -d\< -f1
    ;;
  totalfwtablesize)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=<show><routing><summary></summary></routing></show>" | grep "<total>" | head -n 1 | cut -d\< -f2 | cut -d\> -f2
    ;;
  ipv4fwtablesize)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=<show><routing><summary></summary></routing></show>" | grep "<total>" | head -n 2 | tail -n 1| cut -d\< -f2 | cut -d\> -f2
    ;;
  ipv6fwtablesize)
    curl -s -H "X-PAN-KEY:${APIKEY}" -k "${URLPALOALTO}/api/?type=op&cmd=<show><routing><summary></summary></routing></show>" | grep "<total>" | head -n 3 | tail -n 1| cut -d\< -f2 | cut -d\> -f2
    ;;
  *)
    echo "INVALID PARAMETER"
    usage
    exit 2
esac
