#!/usr/bin/env bash

# letsencrypt 인증서 갱신하기

# 파라미터
while getopts "d:" flag; do
    case "${flag}" in
    d) P__DOMAIN=${OPTARG} ;;
    esac
done

if [[ -z $P__DOMAIN ]]; then
    echo "[FAIL] P__DOMAIN is unset"
    exit 1
fi

DOMAIN=${P__DOMAIN}
DATE_TIME=$(date "+%Y%m%d%H%M%S")

SSL_VOL_ROOT="/var/ssl/"
SSL_VOL_CERT_PATH="${SSL_VOL_ROOT}/certs/${DOMAIN}"
SSL_VOL_BACKUP_PATH="${SSL_VOL_ROOT}/backup/${DOMAIN}"
CERT_FILE="cert.pem"
KEY_FILE="key.pem"
CERT_TYPE="letsencrypt"

LETSENCRYPT_CERT_PATH="/etc/letsencrypt/archive/${DOMAIN}"

echo "Letsencrypt renewal start ... : ${DOMAIN}"

## 인증서 백업
echo "1. backup certification ..."
if [ ! -d "${SSL_VOL_BACKUP_PATH}" ]; then
    mkdir -p ${SSL_VOL_BACKUP_PATH}
fi

if [ -f ${SSL_VOL_CERT_PATH}/${CERT_FILE} ]; then
    cp ${SSL_VOL_CERT_PATH}/${CERT_FILE} ${SSL_VOL_BACKUP_PATH}/${CERT_TYPE}.${DATE_TIME}.${CERT_FILE}
fi

if [ -f ${SSL_VOL_CERT_PATH}/${KEY_FILE} ]; then
    cp ${SSL_VOL_CERT_PATH}/${KEY_FILE} ${SSL_VOL_BACKUP_PATH}/${CERT_TYPE}.${DATE_TIME}.${KEY_FILE}
fi

## 인증서 갱신
echo "2. certbot renew ..."
sudo certbot renew --dry-run

## 인증서 교체
echo "3. Replacing cert files ..."
### 인증서 파일
cp ${LETSENCRYPT_CERT_PATH}/fullchain2.pem ${SSL_VOL_CERT_PATH}/${CERT_FILE}
### 개인키 파일
cp ${LETSENCRYPT_CERT_PATH}/privkey2.pem ${SSL_VOL_CERT_PATH}/${KEY_FILE}

## 웹서비스 재시작
echo "4. restart nginx:nginxd ..."
supervisorctl restart nginx:nginxd

echo "Letsencrypt renewal completed!!"
