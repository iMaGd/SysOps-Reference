# Web Stack Caching & Execution Flow (Nginx + PHP)

## Request Flow

### First request (cache miss)

```
Browser -> Nginx --(FastCGI)-> PHP-FPM → PHP executes → HTML
```

### Subsequent requests (cache hit)

```
Browser → Nginx → Cached HTML → Browser
```

---

## Key Takeaways

* **FastCGI cache**
  * Stores full HTML responses on disk
  * Keeps cache keys indexed in RAM
  * Relies on the Linux page cache to keep hot files in memory
  * Completely bypasses PHP on cache hits

* **Redis**
  * Accelerates PHP execution when PHP *must* run
  * Used for sessions, authentication state, object caching, locks, and queues

* **Clear separation of roles**
  * **FastCGI cache** avoids PHP entirely
  * **Redis** optimizes PHP execution
  * **Disk** stores payloads
  * **RAM** stores indexes and hot data
  * **Linux** manages memory transparently

---

## Common Usage Patterns

* **Redis**
  * Object cache
  * Sessions
  * Queues
  * Locks
    *(supports persistence and replication)*

* **FastCGI cache**
  * Full-page HTML cache

---

## FastCGI Cache Disk Rules

```nginx
fastcgi_cache_path /var/cache/nginx/fastcgi
    inactive=30m
    max_size=10g;
```

#### `inactive=30m`
* Cache file is deleted if not accessed for 30 minutes
* Prevents stale or unused entries from accumulating
* Helps avoid cache rot

#### `max_size=10g`

* Hard size limit for the cache directory
* When reached:
  * Old entries are evicted (LRU-like behavior)
  * Nginx continues running normally

---

### Best Location for FastCGI Cache
* Local SSD
* Preferably the same disk as Nginx
* Avoid network or slow disks

---

### Common Misconceptions (Important)

**“Expired cache is immediately deleted”**
→ No. It is only marked as *stale* and removed lazily.

**“Cache directory grows forever”**
→ No, if `inactive` and `max_size` are configured.

**“You need cron jobs to clean cache”**
→ No. Nginx handles it internally.

---

## Cloudflare Page Cache

**Cache normalization** defines how Cloudflare builds the cache key.

* If set to **“Ignore query strings”**:

  * Cloudflare strips the query string from the URL
  * Uses the normalized URL as the cache key
  * Future requests with different query strings can hit the same cache entry

> This is safe for marketing parameters (e.g. `utm_*`),
but **must not** be used for application-critical query strings.

---

## Memcached

**Memcached** is a pure in-memory key–value store with **no persistence**.

### Best Use Cases

* Repeated database query results
* Computed values
* Small arrays or strings
* Hot lookup tables
* Temporary derived data

### Why Memcached Is Less Popular Today

Redis absorbed most of its use cases by offering:

* Everything Memcached provides
* Plus persistence, queues, locks, and replication

Memcached is still fast, but Redis is more versatile.

---

## Redis

Redis is an in-memory data store with optional persistence.

### Persistence Modes

* **No persistence**
  * Memory-only, fastest, volatile

* **RDB snapshots**
  * Periodic full dumps (`dump.rdb`)
  * Lower write overhead

* **AOF (Append Only File)**
  * Logs every write operation
  * Higher durability

---

## Valkey

* Until March 2024, Redis was fully open-source (BSD license)
* Redis ≥ 7.4 moved to a more restrictive license

**Valkey**:
* Community fork of Redis 7.2
* Governed by the Linux Foundation
* Apache License
* Ensures long-term open governance

Same as **MySQL → MariaDB** story.

---

## Why PHP-FPM Exists

Web servers need **persistent workers**, not disposable processes.

**PHP-FPM (FastCGI Process Manager)** runs PHP as a long-lived service and manages a pool of workers.

It handles:

* Concurrency
* Memory limits
* Request timeouts
* Crashes
* Worker recycling

### Why Not PHP-CLI for HTTP?

Using PHP-CLI per request would mean:

- New process fork
- PHP interpreter boot
- OPcache cold start
- Extensions reloaded
- Significant CPU overhead

> **Always use PHP-FPM for web traffic**

---

## Why PHP-CLI Still Exists

PHP-CLI is a **tool**, not a service.

Use PHP-CLI for:

* Queue workers (`php artisan queue:work`)
* Cron jobs
* Migrations
* One-off scripts
* Background workers
* Tests and local development

---

## FastCGI

**FastCGI is a protocol**, not a library or a server.

It defines how:

* Nginx communicates with PHP-FPM
* Requests and responses are exchanged efficiently

---

## OPcache

**OPcache** stores compiled PHP bytecode in shared memory.

### With OPcache

```text
First request:
  → Compile PHP
  → Store opcodes in RAM

Next requests:
  → Execute opcodes directly from RAM
```

### Without OPcache

* PHP is recompiled on every request
* CPU wasted
* Higher latency
* PHP-FPM workers saturate faster

### Benefits of OPcache

* ~30–70% lower CPU usage per request
* Faster execution
* More requests per worker
* Lower infrastructure cost

Running PHP in production without OPcache is a mistake.
OPcache is the foundation of PHP performance.

---

## Cache layers in nutshell

| Cache Type    | Stored In        | Primary Use Case     |
| ------------- | ---------------- | -------------------- |
| FastCGI cache | Disk + RAM index | Full-page HTML       |
| Redis         | RAM              | Objects, sessions    |
| Memcached     | RAM              | Temporary key-values |
| OPcache       | RAM              | PHP bytecode         |
| Browser cache | Client           | Static assets        |
