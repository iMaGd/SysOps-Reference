# ClamAV

ClamAV is a free and open-source antivirus engine for detecting Trojans, viruses, malware & other malicious threats.

### Installing `ClamAV`

#### malware signatures, web shells, infected PHP files

```bash
sudo apt update
sudo apt install clamav clamav-daemon
```

### Updating signatures
```bash
sudo freshclam
```

### Scanning files
```bash
clamscan -r -i /var/www/site
```
