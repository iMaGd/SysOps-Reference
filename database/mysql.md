
## Install MySQL on Ubuntu 22.04

```bash
sudo apt update
sudo apt upgrade
sudo apt install mysql-server -y

## Secure MySQL
sudo mysql_secure_installation
```
## Start/Stop Service

```bash
# start and enable mysql
sudo systemctl start mysql.service
sudo systemctl enable mysql.service

# Other commands
service mysql start;
service mysql stop;
service mysql restart;
service mysql status;
```

## Login Root user

```bash
sudo mysql
```
or
```
sudo mysql -u root
```

## To Change Password of Root User

```sql
sudo mysql -u root -p

mysql> ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password'

FLUSH PRIVILEGES
```

## Create Admin User

Create a new user `admin` for the host `localhost` with a password:

```sql
mysql> CREATE USER 'admin'@'localhost' IDENTIFIED BY 'some_secure_password';
```

Grant all permissions for all tables to the new admin user

```sql
mysql> GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost';

mysql> FLUSH PRIVILEGES;
```

## Create New User (Isolated)

Create a new user `newuser` for the host `localhost` with a password:

```sql
mysql> CREATE USER 'newuser'@'localhost' IDENTIFIED BY 'some_secure_password';
```

Create a database for this user

```sql
mysql> CREATE database new_db;
```
Grant all permissions for this table to the new user

```sql
mysql> GRANT ALL PRIVILEGES ON new_db.* TO 'newuser'@'localhost';

mysql> FLUSH PRIVILEGES;
```

## Create New Remote User (Isolated)

Create a new user `remote` which can be connected from outside with a password:

```sql
mysql> CREATE USER 'remote'@'%' IDENTIFIED BY 'some_secure_password';
```

Create a database for this user

```sql
mysql> CREATE database new_db;
```
Grant all permissions for this table to the new user

```sql
mysql> GRANT ALL PRIVILEGES ON new_db.* TO 'remote'@'%';

mysql> FLUSH PRIVILEGES;
```

## Grant Remote Access

```bash
nano /etc/mysql/mysql.conf.d/mysqld.cnf
```
change the line containing `bind-address` to `bind-address = 0.0.0.0`
```bash
service mysql restart
```

## To Connect to A Remote Database

```bash
mysql -u root -p -h <host_ip>
```

## Backups
Set up a backup routine for your databases. MySQL's `mysqldump` utility is commonly used for making backups, which can be scheduled with `cron` jobs.


## Monitoring and Logs
Keep an eye on MySQL logs located in `/var/log/mysql/` for errors or issues.


## Regular Database Maintenance
Regularly check your database's health with commands like:
```sql
CHECK TABLE tablename;
ANALYZE TABLE tablename;
OPTIMIZE TABLE tablename;
```


## Troubleshooting
- Check status `service mysql status`
- Check log file at `/var/log/mysql/error.log`
- Check configuration issues `sudo mysqlcheck --all-databases`
- Check disk space available `df -h`


## MySQL Binary Logs

MySQL keeps binary logs (binlogs) for replication & recovery.
Binlogs contain a record of all changes made to the database, allowing for point-in-time recovery and replication.

Binlogs record:
- `INSERT`
- `UPDATE`
- `DELETE`
- schema changes
- transactions

#### Where the binlog files live on disk

```mysql
SHOW VARIABLES LIKE 'log_bin%';
```

output:
```log
/var/lib/mysql/mysql-bin.000001
/var/lib/mysql/mysql-bin.000002
/var/lib/mysql/mysql-bin.000123
```

#### Check binlog expiration

```mysql
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';
```

output (12 hours):
```log
binlog_expire_logs_seconds    43200
```

Or set the expiration time explicitly (runtime + persistent):

```mysql
SET PERSIST binlog_expire_logs_seconds = 43200;
```

#### Purge old binlogs based on time

```mysql
PURGE BINARY LOGS BEFORE NOW() - INTERVAL 12 HOUR;
```

#### Inspect the binlog file

```bash
mysqlbinlog --base64-output=DECODE-ROWS --verbose /var/lib/mysql/binlog.001 | grep -E "^###\s(INSERT|UPDATE|DELETE)" | less -N
```



## Uninstall MySQL
```bash
udo apt purge mysql-server mysql-client mysql-common mysql-server-core-5.5 mysql-client-core-5.5
sudo rm -rf /etc/mysql /var/lib/mysql
sudo apt autoremove
sudo apt autoclean
```