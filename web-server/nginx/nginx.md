## How Nginx Chooses a `server {}` Block

1. **Match port**
   - Request to port `80` → candidates are server blocks with `listen 80;`.
   - Request to port `443` → candidates are server blocks with `listen 443 ssl;`.

2. **Match `server_name`**
   - Nginx checks the `Host:` header from request.
   - Compares it with `server_name` directives in candidate server blocks.
   - Order of precedence:
     1. Exact match (`example.com`)
     2. Longest wildcard match (`*.example.com`)
     3. Regex match (`~^foo\d+\.example\.com$`)
     4. Default/fallback server

3. **Default server**
   - If nothing matches:
     - Uses the `server {}` with `default_server`. (`listen 80 default_server`)
     - If none defined, uses the first `server {}` for that port.

4. **For HTTPS**
   - First chooses certificate via SNI.
   - Then applies the same `server_name` matching.

----

## Configuring Nginx


### Main configuration file

- `/etc/nginx/nginx.conf`

The main config file is the entry point for Nginx. It contains the global configuration directives that apply to all virtual hosts.
In abstract terms, it defines the following:

-   **Events**: Configures worker connections.
-   **HTTP**: Defines the server block for handling HTTP requests.

```nginx
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;

        location ~ \.php$ {
        }
    }
}
```
> This a big picture about the hierarchy of a Nginx configuration file.
Everything defined in `http` block is global and is available in `server` and `location` blocks and CANNOT be overwriten by them.

### Default Virtual Site

The default virtual site is the site that Nginx serves when no other site matches the request.
It is typically used to redirect requests to a default domain or to display a 404 error.



Otherwise, you can create a default virtual site by creating a configuration file in the `/etc/nginx/sites-available/` directory.

```bash
nano /etc/nginx/sites-available/example.conf
```

```
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/example/public;

    index index.html index.htm index.php;

    client_max_body_size 32M;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php7.4-fpm.sock;
    }
}
```

### Link to Enabled Sites
```bash
sudo ln -s /etc/nginx/sites-available/example /etc/nginx/sites-enabled/
```

-----

### Location Modifiers

-   `location = /path`\
    Exact match. Highest priority.

-   `location ^~ /path/`\
    Prefix match. If matched, **stop searching** (ignores regex).

-   `location ~ pattern`\
    Regex match (case-sensitive). First defined regex that matches is
    used.

-   `location ~* pattern`\
    Regex match (case-insensitive).

-   `location /path/`\
    Prefix match (longest wins if multiple).

## Priority Order

1.  Exact match (`=`)\
2.  Prefix match with `^~`\
3.  Regex matches (`~`, `~*`) → first defined wins\
4.  Longest normal prefix match

## Example

``` nginx
location = /favicon.ico   { ... }   # exact
location ^~ /images/      { ... }   # prefix, stop search
location ~ \.php$         { ... }   # regex (case-sensitive)
location /                { ... }   # fallback prefix
```



----

### SSL on Ports

- Port 443 is the well-known default for HTTPS.
- You can enable TLS on any TCP port.
- The port must be configured with a TLS certificate and knows how to handle the TLS handshake.

**Configuration for enabling TLS on port 8443**

```
# /etc/nginx/sites-available/domain.com

# 1. HTTP on :80 (no TLS) — redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name domain.com www.domain.com;

    return 301 https://$host$request_uri;
}

# 2. HTTPS on :443
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name domain.com www.domain.com;

    # We can also listen on multiple TLS ports
    listen 5443 ssl http2;

    ssl_certificate     /etc/ssl/certs/domain.com.fullchain.pem;
    ssl_certificate_key /etc/ssl/private/domain.com.key;

    # (optional hardening)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /var/www/domain.com/public;
    index index.php index.html;
}

# 3) HTTPS on :8443 (same cert; different port)
server {
    listen 8026 ssl http2;
    listen [::]:8026 ssl http2;
    server_name domain.com;

    ssl_certificate     /etc/ssl/certs/domain.com.fullchain.pem;
    ssl_certificate_key /etc/ssl/private/domain.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # You can serve a different app/root here if you want
    root /var/www/domain.com-8026/public;
    index index.php index.html;
}
```

**Reload the webserver**
```
sudo nginx -t && sudo service nginx reload
```

----

### Config for WordPress Multisite Using Directories

```nginx
server {
    listen 80;
    server_name ww.example.com;

    root /var/www/wpmu;
    index index.php;

    client_max_body_size 32M;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ ^/[_0-9a-zA-Z-]+/files/(.*)$ {
        try_files /wp-content/blogs.dir/$blogid/$uri /wp-includes/ms-files.php?file=$1 ;
        access_log off; log_not_found off; expires max;
    }

    # Avoid PHP parsing for known requests
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm-wpmu.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Directives to send expires headers and turn off 404 error logging.
    location ~* ^/[_0-9a-zA-Z-]+/(wp-(content|admin|includes).*) {
        try_files $uri $uri/ /index.php?$args ;
    }

    location ~* ^/[_0-9a-zA-Z-]+/(.*\.php)$ {
        try_files $uri /index.php?$args ;
    }

    location ~ /xmlrpc.php$ {
        deny all;
    }
}
```
-------

### Config for CraftCMS

```
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;

    root /home/my-user/apps/my-app/web;

    # Allow Let's Encrypt HTTP-01 challenge without forcing HTTPS
    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        allow all;
    }

    # Everything else redirects to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }

    access_log /var/log/nginx/my-app_access_http.log;
    error_log  /var/log/nginx/my-app_error_http.log;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    root /home/my-user/apps/my-app/web;
    index index.php index.html;

    # ---- SSL (adjust to your cert paths or your ACME client) ----
    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # HSTS (enable after confirming HTTPS works; preload optional)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    # Tweak CSP to your needs; this permissive example supports inline scripts, etc.
    add_header Content-Security-Policy "default-src 'self' https: data: blob: 'unsafe-inline' 'unsafe-eval'" always;

    # Logs
    access_log /var/log/nginx/my-app_access.log;
    error_log  /var/log/nginx/my-app_error.log;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript application/xml+rss image/svg+xml;
    gzip_min_length 256;

    # ------------------------
    # Block sensitive things
    # ------------------------

    # Never serve dotfiles (.env, .htpasswd, .git, etc.)
    location ~ /\.(?!well-known) {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Extra hardening against accidental placement of .htpasswd in web root
    location = /.htpasswd { deny all; return 404; }

    # Deny access to private folders and common project files if exposed
    location ~* ^/(config|storage|vendor|node_modules|tests)(/|$)  {
        deny all;
        return 404;
    }
    location ~* ^/(composer\.json|composer\.lock|yarn\.lock|package\.json)$ {
        deny all;
        return 404;
    }

    # ------------------------
    # CMS routing
    # ------------------------
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Static assets caching
    location ~* \.(ico|css|js|gif|jpe?g|png|webp|svg|woff2?|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, max-age=2592000, immutable";
        access_log off;
        try_files $uri =404;
    }

    # PHP-FPM handling (adjust PHP version/socket)
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;  # or 127.0.0.1:9000
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME     $fastcgi_script_name;
        fastcgi_index index.php;

        # Useful buffers/timeouts for Craft (CP, image transforms)
        fastcgi_buffers 8 16k;
        fastcgi_buffer_size 32k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Error handling: let Craft render 404/50x via index.php
    error_page 404 /index.php;
    error_page 500 502 503 504 /index.php;

    # ----------------------------------------------
    # Password-protected directory (/protected)
    # Place real files under: /home/my-user/apps/my-app/web/protected
    # Keep .htpasswd OUTSIDE the web root, e.g. /home/my-user/secure/.htpasswd
    location ^~ /protected/ {
        auth_basic           "Restricted Area";
        auth_basic_user_file /home/my-user/secure/.htpasswd;

        try_files $uri $uri/ /index.php?$query_string;
    }
}
```

-------

## Pass Protect Directory

See [htpasswd guide](./htpasswd.md) for password protecting directories

---

### Main `nginx.conf` (High-Traffic/Production)

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    use epoll;
    multi_accept on;
    worker_connections 65535;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 65;
    keepalive_requests 100000;

    server_tokens off;

    client_max_body_size 64m;
    client_body_buffer_size 128k;
    client_body_timeout 60s;
    client_header_timeout 60s;
    large_client_header_buffers 4 16k;

    open_file_cache max=10000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_disable "msie6";
    gzip_comp_level 5;
    gzip_buffers 16 8k;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/font-woff application/x-font-ttf image/svg+xml;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    error_log  /var/log/nginx/error.log warn;

    resolver 1.1.1.1 1.0.0.1 valid=300s;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```

### Main `nginx.conf` (Behind Cloudflare)

```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    <!-- optimal for Linux, high concurrency -->
    use epoll;
    multi_accept on;
    worker_connections 65535;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;

    keepalive_timeout 65;
    keepalive_requests 100000;

    server_tokens off;

    real_ip_header CF-Connecting-IP;
    real_ip_recursive on;
    set_real_ip_from 173.245.48.0/20;
    set_real_ip_from 103.21.244.0/22;
    set_real_ip_from 103.22.200.0/22;
    set_real_ip_from 103.31.4.0/22;
    set_real_ip_from 141.101.64.0/18;
    set_real_ip_from 108.162.192.0/18;
    set_real_ip_from 190.93.240.0/20;
    set_real_ip_from 188.114.96.0/20;
    set_real_ip_from 197.234.240.0/22;
    set_real_ip_from 198.41.128.0/17;
    set_real_ip_from 162.158.0.0/15;
    set_real_ip_from 104.16.0.0/13;
    set_real_ip_from 104.24.0.0/14;
    set_real_ip_from 172.64.0.0/13;
    set_real_ip_from 131.0.72.0/22;
    set_real_ip_from 2400:cb00::/32;
    set_real_ip_from 2606:4700::/32;
    set_real_ip_from 2803:f800::/32;
    set_real_ip_from 2405:b500::/32;
    set_real_ip_from 2405:8100::/32;
    set_real_ip_from 2a06:98c0::/29;
    set_real_ip_from 2c0f:f248::/32;

    client_max_body_size 64m;
    client_body_buffer_size 128k;
    client_body_timeout 60s;
    client_header_timeout 60s;
    large_client_header_buffers 4 16k;

    open_file_cache max=10000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_disable "msie6";
    gzip_comp_level 5;
    gzip_buffers 16 8k;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/font-woff application/x-font-ttf image/svg+xml;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;
    error_log  /var/log/nginx/error.log warn;

    resolver 1.1.1.1 1.0.0.1 valid=300s;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
```


-----

### ServerPilot

```nginx
error_log  /var/log/nginx-sp/error.log;

pid        /var/run/nginx-sp.pid;

<!-- global tuning (buffers, limits, maps) -->
include    /etc/nginx-sp/core.d/*.conf;

events {
    multi_accept on;
    use epoll;
    <!-- worker / connection tuning -->
    include /etc/nginx-sp/events.d/*.conf;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    server_tokens off;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for" '
                      '$request_length $request_time '
                      '"$upstream_response_length" "$upstream_response_time" "$host"';

    access_log  /var/log/nginx-sp/access.log  main;

    server_names_hash_max_size 65536;
    server_names_hash_bucket_size 1024;  # Max length of domain names.
    types_hash_max_size 2048;

    sendfile        on;

    gzip         on;
    # text/html does not need to be listed as it is always included by nginx.
    # WOFF files are already compressed, so application/x-font-woff is not needed.
    gzip_types   text/plain text/css application/json
                 text/javascript application/javascript application/x-javascript
                 text/xml application/xml application/xml+rss image/svg+xml
                 application/vnd.ms-fontobject application/x-font-ttf font/opentype;
    gzip_vary    on;
    gzip_disable "msie6";

    # CloudFlare proxy addresses.
    # Do not modify this list. If you believe the CloudFlare proxy address list is
    # out of date, please contact support@serverpilot.io.
    set_real_ip_from    103.21.244.0/22;
    set_real_ip_from    103.22.200.0/22;
    set_real_ip_from    103.31.4.0/22;
    set_real_ip_from    104.16.0.0/13;
    set_real_ip_from    104.24.0.0/14;
    set_real_ip_from    108.162.192.0/18;
    set_real_ip_from    131.0.72.0/22;
    set_real_ip_from    141.101.64.0/18;
    set_real_ip_from    162.158.0.0/15;
    set_real_ip_from    172.64.0.0/13;
    set_real_ip_from    173.245.48.0/20;
    set_real_ip_from    188.114.96.0/20;
    set_real_ip_from    190.93.240.0/20;
    set_real_ip_from    197.234.240.0/22;
    set_real_ip_from    198.41.128.0/17;
    set_real_ip_from    2400:cb00::/32;
    set_real_ip_from    2405:8100::/32;
    set_real_ip_from    2405:b500::/32;
    set_real_ip_from    2606:4700::/32;
    set_real_ip_from    2803:f800::/32;
    set_real_ip_from    2a06:98c0::/29;
    set_real_ip_from    2c0f:f248::/32;

    real_ip_header      X-Forwarded-For;

    <!-- shared snippets -->
    include /etc/nginx-sp/conf.d/*.conf;
    <!-- HTTP-level behaviour (maps, limits, WAF-like rules) -->
    include /etc/nginx-sp/http.d/*.conf;
    <!-- per-site config -->
    include /etc/nginx-sp/vhosts.d/*.conf;
    <!-- overrides / final rules -->
    include /etc/nginx-sp/last.d/*.conf;
}
```

###

Nginx values can be set in:

- `http {}`
- `server {}`
- `location {}`

```
events{}

http {
    proxy_read_timeout 60s;

    server {
        proxy_read_timeout 90s;

        location /admin {
            proxy_read_timeout 120s;
        }
    }
}
```

**Result:**
- / = 90s
- /admin = 120s

## Common Variables in Nginx:

#### Nginx variable scoping works like this:

- **`http` block**: Global configuration, executed once
- **`server` block**: Per virtual host, can access http-level variables
- **`location` block**: Per URL pattern, can access server-level and http-level variables

---


**`$scheme`** = `http` or `https` ✓ (same as custom)

**`$proxy_host`** = The hostname from the `proxy_pass` directive
- Used for **reverse proxy** scenarios
- For FastCGI, this would be empty or irrelevant

**`$uri`** = Normalized URI **without** query string
- Example: `/blog/post` (strips `?id=123`)

**`$is_args`** = `?` if query string exists, empty otherwise

**`$args`** = Query string parameters
- Example: `id=123&page=2`

**`$query_string`** = Query string parameters
- Example: `id=123&page=2`

> **`$args`** and **`$query_string`** are the same, they are alias for each other.

**`$request_method`** = `GET`, `POST`, `HEAD`, etc.

**`$host`** = The domain name from the request
- Example: `example.com` or `www.example.com`

**`$request_uri`** = Full URI **including** query string
- Example: `/blog/post?id=123`

**`$remote_addr`** = Client IP address
- Example: `123.45.67.89`
