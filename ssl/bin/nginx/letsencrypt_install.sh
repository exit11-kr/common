#!/usr/bin/env bash

# letsencrypt 인증서 설치하기

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
LETSENCRYPT_CERT_PATH="/etc/letsencrypt/archive/${DOMAIN}"
WS_CERT_PATH="/var/www/ssl/certs/${DOMAIN}"
VHOST_SSL_CONF_PATH="/opt/docker/etc/nginx/vhost.ssl.conf"
CERT_FILE="cert.pem"
KEY_FILE="key.pem"

echo "Letsencrypt install start ... : ${DOMAIN}"

echo "1. apt-get install letsencrypt ..."
apt-get install letsencrypt

echo "2. sudo letsencrypt ..."
# sudo letsencrypt certonly --webroot --webroot-path=/var/www/html/public -d ${DOMAIN} -d www.${DOMAIN}
sudo letsencrypt certonly --webroot --webroot-path=/var/www/html/public -d ${DOMAIN}

## 인증서 교체
echo "3. Replacing cert files ..."
if [ ! -d "${WS_CERT_PATH}" ]; then
    mkdir -p ${WS_CERT_PATH}
fi
cp ${LETSENCRYPT_CERT_PATH}/fullchain2.pem ${WS_CERT_PATH}/${CERT_FILE}
cp ${LETSENCRYPT_CERT_PATH}/privkey2.pem ${WS_CERT_PATH}/${KEY_FILE}

# 인증서 경로 수정: /opt/docker/etc/nginx/vhost.ssl.conf
echo "4. Update cert path(vhost.ssl.conf) ..."
sed -i "s%\(ssl_certificate[ \t]\+\)[a-z/.]\+;%\1${WS_CERT_PATH}/${CERT_FILE};%g" ${VHOST_SSL_CONF_PATH}
sed -i "s%\(ssl_certificate_key[ \t]\+\)[a-z/.]\+;%\1${WS_CERT_PATH}/${KEY_FILE};%g" ${VHOST_SSL_CONF_PATH}
## sed -i "s%\(ssl_protocols[ \t]\+\)[a-z/.]\+;%\1TLSv1.2 TLSv1.3;%g"  ${VHOST_SSL_CONF_PATH}
## sed -i "s%\(ssl_ciphers[ \t]\+\)[a-z/.]\+;%\1ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;%g"  ${VHOST_SSL_CONF_PATH}

## 웹서비스 재시작
echo "5. restart nginx:nginxd ..."
supervisorctl restart nginx:nginxd

# 인증서 갱신 스크립트 cron 항목으로 등록: 매월 5일 새벽1시에 갱신
## 분-시간-일-월-요일
echo "6. Crontab: Runs at 1 AM every 60 days ..."
(
    crontab -u root -l
    echo "0 1 5 * * cd /usr/local/bin && ./php /var/www/ssl/bin/letsencrypt_renew.sh >> /dev/null 2>&1"
) | crontab -u root -

echo "Letsencrypt install completed!!"
