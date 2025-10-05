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

Simple example:

```bash
nano /etc/nginx/sites-available/example.conf
```

### Default Virtual Site
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
