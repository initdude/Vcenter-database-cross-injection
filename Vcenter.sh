#!!!!!WARNING!!!!! make sure that you have dumped the old vcenter's database and it's healthy then start this steps:
#ssh to vcenter server
#shell

on the corrupted vcenter :
take a dump from database:

$ pg_dump -U postgres VCDB > /tmp/vcdb_backup.sql
##send the backedup database to your system or a safe system to import from it later.

when you compeletely exported the database and send it to a safe system, then install a new vcenter and insert the database in it.

enter to databse:
$ /opt/vmware/vposgres/15[version]/bin/psql -U postgres
\l   #lists all databases 
DROP DATABASE VCDB; #removes currnet database, do it fast because postgres will craete a new session for it and it wont drop
CREATE DATABASE VCDB;
\q
##important not:
If you encounter this error while dropping the database, follow these steps:
Error:
"DROP DATABASE "VCDB";
ERROR:  database "VCDB" is being accessed by other users
DETAIL:  There are "some number" other sessions using the database."

Solution of the error: #in the postgres 

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'VCDB' AND pid <> pg_backend_pid();


psql -U postgres VCDB < /tmp/vcdb_backup.sql #import the database
 you are all done.
