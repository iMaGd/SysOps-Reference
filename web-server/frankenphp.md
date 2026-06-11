
## How It Works

FrankenPHP is PHP embedded directly inside **Caddy**, so dont need a web server.

![Image](https://www.net7.be/assets/images/news/frankenphp/frankenphp_schema.png)


FrankenPHP already provides:

* HTTP server
* HTTPS (automatic TLS via Caddy)
* HTTP/2 + HTTP/3
* Static file serving
* Reverse proxy support
* Worker mode (Octane-style)

------

## Main FrankenPHP Modes

FrankenPHP has five main modes:

| Mode       | Best For         | Performance | Compatibility |
| ---------- | ---------------- | ----------- | ------------- |
| Standalone | Laravel/Symfony/Craft | High        | High          |
| Worker     | Laravel/Symfony  | Very High   | Medium        |
| Classic    | WordPress/Craft  | Medium-High | Very High     |
| Caddyfile  | Complex infra    | High        | High          |
| Embedded   | Custom platforms | Depends     | Advanced      |


## 1. **Standalone Web Server Mode**

FrankenPHP acts as:

* HTTP server (Caddy-based)
* PHP runtime
* Process manager

### Use case:

* Replace **Nginx + PHP-FPM**
* Simple deployments
* Dockerized apps
* Recommended for many Laravel / Symfony / Craft apps

### Sample command

```bash
frankenphp php-server
```

### Features:

* Built-in HTTPS via Caddy
* Static file serving
* HTTP/2 + HTTP/3
* Reverse proxy support
* No PHP-FPM needed

---

# 2. **Worker Mode (Persistent App / Long-lived PHP Workers)**

This is one of FrankenPHP’s biggest advantages.

### Use case:

* Laravel Octane
* Symfony Runtime
* High-performance apps
* Reduced bootstrap cost

### How it works:

* PHP app bootstraps once
* Worker handles many requests
* Similar concept to RoadRunner / Swoole

### Benefits:

* Much faster than classic PHP-FPM
* Lower latency
* Better throughput

### Example:

```bash
FRANKENPHP_CONFIG="worker ./public/index.php"
frankenphp run
```

---

# 3. **Classic Mode / PHP-FPM Compatibility**

FrankenPHP can behave more like traditional request-per-process PHP.

### Use case:

* Legacy PHP apps
* WordPress
* Craft CMS
* Apps not designed for persistent workers

### Characteristics:

* Each request isolated
* More compatibility
* Slightly less performance than worker mode

---

# 4. **Caddyfile Custom Server Mode**

Because FrankenPHP is built on Caddy, you can run it with a custom Caddyfile.

### Use case:

* Reverse proxy
* Multiple sites
* TLS customization
* Static + dynamic hybrid

### Example:

```bash
frankenphp run --config Caddyfile
```

### Example Caddyfile:

```caddy
:80 {
    root * /app/web
    php_server
}
```

---

# 5. **Embedded / Library Mode**

FrankenPHP can be embedded into Go applications.

### Use case:

* Custom hosting platforms
* PaaS
* Advanced infrastructure

### Mostly for:

* Go developers
* Platform engineers

---

# 6. **Docker Mode**

Official Docker images support multiple startup styles.

### Common:

```bash
docker run dunglas/frankenphp
```

### Variants:

* Standalone
* Worker
* Custom Caddyfile
* Production images

---

# Practical Breakdown for Your Use Cases

## For Craft CMS:

### Best:

**Classic / php_server mode**
Because Craft plugins may not always be worker-safe.

```bash
frankenphp php-server --root web/
```

---

## For Laravel:

### Best:

**Worker mode**
Especially with Octane.


# Bottom Line

* **php-server mode** → easiest
* **worker mode** → fastest

* **Craft/WordPress:** Classic
* **Laravel SaaS / Shopify:** Worker
* **Multi-tenant edge stack:** Caddyfile mode
