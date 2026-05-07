
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


## Two Modes It Can Run In

### 1. Classic mode (like PHP-FPM replacement)

- Each request bootstraps Laravel normally.
- Safe. Simple. Drop-in replacement.


### 2. Worker mode (Octane-style)

App stays in memory.

- High performance.
- More responsibility.
