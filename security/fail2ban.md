### Install Fail2ban

```bash
sudo apt update
sudo apt install fail2ban -y
```

### Base Configuration

The `/etc/fail2ban/jail.conf` file provides default settings of fail2Ban and is overwritten on updates. It is not recommended to edit this file directly. Instead, you can create a `override.local` file (any file name with .local extension) and just add the changes or specific configurations that you wish to override or extend.

The `override.local` file is read after `jail.conf`, and settings in `override.local` will override any corresponding settings in `jail.conf`.


To override or define new jails create and edit following file

```bash
sudo nano /etc/fail2ban/jail.d/override.local
```

Add following to your file:

```ini
[DEFAULT]
ignoreip = 127.0.0.1/8 ::1 your_trusted_ip
bantime.increment = true
bantime.factor = 1
bantime = 10m
findtime = 10m
maxretry = 5
backend = auto
usedns = warn
logencoding = auto
```

- `ignoreip`: IP addresses and networks that should never be banned. You could add your own IP address to avoid getting locked out.
- `bantime`: The duration (seconds/minutes/hours/days) that an IP will be banned.
- `findtime`: The time window during which repeated failures from the same IP will be counted (seconds/minutes/hours).
- `maxretry`: The number of failures before an IP is banned within the `findtime`.

Below the `[DEFAULT]` section, you can specify individual jails for services you wish to protect (e.g., SSH, Apache, Nginx). For instance, to protect SSH, you might have:

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
```

**Activating Changes:**

To activate the changes, restart the service:

```bash
sudo service fail2ban restart
```

**Monitoring Fail2ban:**

Check the status of a all jails:

```bash
sudo fail2ban-client status
```

Check the status of a specific jail:

```bash
sudo fail2ban-client status sshd
```

To view banned IPs:

```bash
sudo iptables -L f2b-sshd -n -v
```

Replace `sshd` with the relevant jail name.


-------------------

### Boilerplate

[Fail2Ban Install and Config Script](../scripts/fail2ban.sh)