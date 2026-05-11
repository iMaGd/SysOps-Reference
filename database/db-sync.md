echo -e "Dumping DB\n"

# Dump the Prod DB
mysqldump --host=the.host.com --user=db_user --lock-tables=false --no-tablespaces --column-statistics=0 --skip-network-timeout --set-gtid-purged=OFF -ppassword db_name_origin > ./tmpSync/backup.sql

echo -e "Importing DB\n"

# Import the DB to Staging
#mysql --host=the.host.com --user=db_user -password db_name_destination < ./tmpSync/backup.sql
mysql --host=127.0.0.1 --user=db_user -ppassword db_name_destination < ./tmpSync/backup.sql

echo -e "\nDone"
