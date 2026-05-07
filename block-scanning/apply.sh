#!/usr/bin/env bash
set -e

# Configuration variables
# (MAKE SURE TO UPDATE THESE BEFORE RUNNING)
NGINX_DIR_NAME="nginx"
NGINX_CONF_DIR="/etc/${NGINX_DIR_NAME}"
FAIL2BAN_CONF_DIR="/etc/fail2ban"
ALLOWED_IPS="127.0.0.1/8 ::1 103.0.0.1"

echo "==> Applying Nginx + Fail2ban config"

# --- sanity checks ---
if [[ $EUID -ne 0 ]]; then
  echo "Run as root"
  exit 1
fi

# --- Nginx ---
echo "==> Applying nginx fuzzer-waf config"
cp -f nginx/http.d/fuzzer-waf.conf "${NGINX_CONF_DIR}/http.d/"

mkdir -p "${NGINX_CONF_DIR}/snippets/"
cp -f nginx/snippets/return-444.conf "${NGINX_CONF_DIR}/snippets/return-444.conf"


# Add return-444.conf to each vhost
VHOST_ROOT="${NGINX_CONF_DIR}/vhosts.d"

for VHOST_DIR in "$VHOST_ROOT"/*; do
  if [[ -d "$VHOST_DIR" ]]; then
    ln -sf "${NGINX_CONF_DIR}/snippets/return-444.conf" "$VHOST_DIR/return-444.conf"
  fi
done

# apply nginx config
"${NGINX_DIR_NAME}" -t
systemctl reload "${NGINX_DIR_NAME}"

# --- Fail2ban ---
echo "==> Installing fail2ban filter"
cp -f fail2ban/filter.d/nginx-444.conf "${FAIL2BAN_CONF_DIR}/filter.d/"

echo "==> Installing fail2ban jail"
cp -f fail2ban/jail.d/nginx-444.local "${FAIL2BAN_CONF_DIR}/jail.d/"

# Update logpath to use NGINX_DIR_NAME
sed -i "s|/var/log/nginx.*|/var/log/${NGINX_DIR_NAME}/*.log|" "${FAIL2BAN_CONF_DIR}/jail.d/nginx-444.local"

# Replace placeholder IPs with configured allowed IPs
sed -i "s|ignoreip = .*|ignoreip = ${ALLOWED_IPS}|" "${FAIL2BAN_CONF_DIR}/jail.d/nginx-444.local"

service fail2ban restart

echo "==> Done"
