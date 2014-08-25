#!/bin/bash


genpasswd() {
    local l=$1
    [ "$l" == "" ] && l=16
    RES=$(tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs)
    echo $RES
}

# use base64 encoding
MYENCPASS="bXlTZWNyZXRQYXNzd29yZAo=" # echo "mySecretPassword" | base64
echo $MYENCPASS

MYPASS=`echo "$MYENCPASS" | base64 --decode`
echo $MYPASS

# using openssl
MYENCPASS='yQA4stTBI8njgNgdmttwjlcFrywQD4XEIgK8HzqEOxI='
MYPASS=`echo "$MYENCPASS" | openssl enc -base64 -d -aes-256-cbc -nosalt -pass pass:garbageKey`
echo $MYPASS