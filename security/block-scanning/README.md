# How this protection works

1. **Nginx is the first line of defence**
- Requests **without a `Host` header** are immediately rejected with 444 response code.
- Common fuzzer and scanner patterns (e.g. path traversal, `.env`, `wp-admin`, malformed URLs) are detected at the Nginx level.
- Nginx responds with **HTTP `444`**, silently dropping the connection without sending a response body.

2. **Malicious traffic never reaches the application**
- `444` responses terminate the request early.
- PHP, upstream services, and the application layer are never engaged.

3. **Fail2ban continuously scans Nginx access logs**
- All relevant Nginx logs (global and per-vhost) are monitored via wildcard paths.
- Fail2ban watches specifically for **HTTP `444` response codes**.

4. **Rate-based banning is applied**
- If an IP generates **too many `444` responses within a short time window**, it is classified as malicious.
- The IP is blocked at the **firewall level** (iptables / nftables).

5. **Automatic escalation for repeat offenders**
- Initial ban is short (10 minutes).
- Repeated offences cause the **ban time to double automatically**, up to a defined maximum.
- This discourages persistent scanners and repeated bot attempts.

#### Result
- Legitimate users are unaffected.
- Scanners are dropped instantly, then actively blocked.
- Protection is **centralised, repeatable, and consistent across servers**.

----

# Setup

### Prerequisites
- Nginx installed and configured on the server.
- Fail2ban installed and configured on the server.
```bash
apt install fail2ban -y
```
- Make sure the server is authorized to be connected to the repository.
- Make a new SSH key pair for the server.
- Add the public key to the repository's accepted keys under repo settings.
```
ssh-keygen -t ed25519 -C "email@example.com"
```
- iptables or nftables firewall with fail2ban integration.
- Make sure there is no WordPress website on the server since the rules are going to block all requests to `/wp-*` paths.
```bash
sudo find /var/www /home /srv/users -type f -name wp-config.php 2>/dev/null
```
- Make sure in the public directory of the websites the only php file is `index.php`.
```bash
find /srv/users/ -type d -path "*/public" ! -path "*/vendor/**/public"
```

### 1. IF first time clone
Clone the repo on the server (make sure to copy server public key to the repo's accepted keys under repo settings)

```bash
git clone git@bitbucket.org:SimpleIM/sysops-scripts.git ~/scripts/sysops/
sudo chmod +x ~/scripts/sysops/block-scanning/apply.sh

# Edit the env file and add the allowed IPs
sudo cp ~/scripts/sysops/block-scanning/.env.example ~/scripts/sysops/block-scanning/.env
sudo nano ~/scripts/sysops/block-scanning/.env
```

### 2. If already cloned

```bash
cd ~/scripts/sysops/ && git pull
```

### 3. Apply the rules

Navigate to the block-scanning directory and apply the rules
```bash
cd ~/scripts/sysops/block-scanning/
# apply the rules
./apply.sh
```

# Useful Commands

### Check the nft ruleset for firewall rules related to fail2ban
```bash
sudo nft list ruleset
sudo nft list ruleset | grep f2b -A10
```

### Check the ban status
```bash
sudo fail2ban-client status
sudo fail2ban-client status nginx-444
sudo grep "Ban " /var/log/fail2ban.log

sudo nft list ruleset | grep f2b -A10
```

### Unblock an IP
```bash
sudo fail2ban-client set nginx-444 unbanip 10.10.10.10
```

### Modify Fail2ban configuration
```bash
sudo nano /etc/fail2ban/jail.d/nginx-444.conf
```

## Monitoring

#### Tracing 444, 503, and 404 responses
```bash
tail -f /srv/users/*/log/*/*nginx.access*.log /var/log/nginx*/access*.log | grep -E '\" (444|404|503)'
```

#### Check the ban status for jail
```bash
sudo fail2ban-client status nginx-444
```

#### Check blocked IPs by Fail2ban
```bash
sudo nft list ruleset | grep f2b -A10
```

#### Why IP is blocked
```bash
grep -h 'x.x.x.x' /srv/users/*/log/*/*nginx.access*.log /var/log/nginx*/access*.log | grep -E "(404|444|503)" | less
```

#### Block IP range manually
```bash
# 1. Create rule table (if not exists)
sudo nft add table inet bad-ips

# 2. Create the INPUT chain (if not exists)
sudo nft add chain inet bad-ips input { type filter hook input priority 0 \; policy accept \; }

# Add the rule to block the IP range
nft add rule inet bad-ips input ip saddr x.x.x.0/24 drop
```
