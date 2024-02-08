#!/usr/bin/env bash

# Ubuntu 자체서명 인증서 설치

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
WS_CERT_PATH="/var/ssl/certs/${DOMAIN}"
CERT_FILE="cert.pem"
KEY_FILE="key.pem"

# openssl version

# 설치안된 경우 설치
sudo apt update
suto apt install openssql

# 폴더 생성
mkdir ~/certs
cd ~/certs

# 개인키 생성
openssl genrsa -des3 -out server.key 2048

# 인증요청서 생성: 서버 개인키 패스워드 입력
openssl req -new -key server.key -out server.csr
## KR, Busan, Busanjin-gu, Seintech, Seintech, www.seinetech.co.kr

# (Optional) 개인키에서 패스워드 제거
cp server.key server.key.origin
openssl rsa -in server.key.origin -out server.key

# 인증서 생성(유효기간: 10년)
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

# 확인
## 개인키
cat server.key | head -3

## 사설인증서
cat server.crt | head -3

# 개인키와 인증서 생성
openssl x509 -inform PEM -in server.crt >${WS_CERT_PATH}/${CERT_FILE}
openssl rsa -in server.key -text >${WS_CERT_PATH}/${KEY_FILE}

## 웹서비스 재시작
supervisorctl restart nginx:nginxd
