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

### Result
- Legitimate users are unaffected.
- Scanners are dropped instantly, then actively blocked.
- Protection is **centralised, repeatable, and consistent across servers**.

----

# Setup

### 1. IF first time clone
Clone the repo on the server (make sure to copy server public key to the repo's accepted keys under repo settings)

```bash
git clone git@bitbucket.org:SimpleIM/sysops-scripts.git /scripts/sysops/
sudo chmod +x /scripts/sysops/block-scanning/apply.sh
```

### 2. If already cloned

```bash
cd /scripts/sysops/ && git pull
```

### 3. Apply the rules

Navigate to the block-scanning directory and apply the rules
```bash
cd /scripts/sysops/block-scanning/
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
```

### Unblock an IP
```bash
sudo fail2ban-client set nginx-444 unbanip 10.10.10.10
```
