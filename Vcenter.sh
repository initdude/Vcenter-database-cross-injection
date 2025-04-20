pfp
I want to extract vcenter database in postgresql and install a new vcenter then insert the old data base to new one, because my old vcenter servises has been dameged


25 Websites
Migrating a vCenter Server database from an existing PostgreSQL (vPostgres) instance to a new vCenter Server Appliance (VCSA) involves several critical steps. Since your old vCenter services are damaged, the goal is to back up the existing vPostgres database, deploy a new VCSA, and restore the database to the new instance. Below is a detailed, step-by-step guide based on VMware best practices and available information. Note that restoring a vPostgres database to a different vCenter instance is not officially supported by VMware, so proceed with caution and ensure you have backups. Always consult VMware Global Support Services (GSS) before performing such operations in a production environment.

Prerequisites
Verify Compatibility: Ensure the source and target vCenter Server versions are compatible. The database schema must match the vCenter version (e.g., vCenter 6.5 to 6.5 or 7.0 to 7.0).
Access to Source VCSA: You need SSH or console access to the damaged VCSA with root credentials to attempt database extraction.
Backup Tools: Use tools like PuTTY (SSH) and WinSCP (file transfer) to access and copy files.
New VCSA Setup: Prepare an ESXi host or vSphere environment to deploy the new VCSA.
PostgreSQL Knowledge: Familiarity with PostgreSQL commands is helpful for manual database operations.
Snapshot/Backup: Take a snapshot or full backup of the source VCSA (if possible) and the new VCSA before making changes.
Database Credentials: Retrieve the database credentials from the source VCSA.
Step 1: Extract the vPostgres Database from the Source VCSA
Since the vCenter services are damaged, you may not be able to use the vCenter Management Interface (VAMI) for backups. Instead, you’ll manually extract the database using VMware-provided scripts or PostgreSQL tools.

Access the Source VCSA:
Log in to the source VCSA via SSH as the root user using PuTTY or the vSphere console.
Switch to the BASH shell by typing shell.
Retrieve Database Credentials:
Locate the vcdb.properties file at /etc/vmware-vpx/vcdb.properties.
Open the file using a text editor (e.g., vi /etc/vmware-vpx/vcdb.properties) to find the database name (usually VCDB), username (e.g., vc), and password.
Example content:
text

url = jdbc:postgresql://localhost:5432/VCDB
username = vc
password = <your_password>
Back Up the vPostgres Database:
VMware provides Python scripts for backing up the vPostgres database, as described in VMware KB article 2091961.
Download the script package 2091961_linux_backup_restore.zip from the VMware KB article (requires VMware account access) and transfer it to the VCSA using WinSCP.
Unzip the file on the VCSA:
bash

unzip 2091961_linux_backup_restore.zip -d /tmp/backup
Run the backup script to create a database dump:
bash

/tmp/backup/backup_lin.py -f /tmp/vcdb_backup.sql
This creates a backup file (vcdb_backup.sql) in the /tmp directory.
Alternatively, use the pg_dump command manually if the script fails:
bash

/opt/vmware/vpostgres/current/bin/pg_dump -U postgres -d VCDB > /tmp/vcdb_backup.sql
Note: Replace postgres with the username from vcdb.properties if different (e.g., vc).
Copy the Backup File:
Use WinSCP to copy the vcdb_backup.sql file from /tmp to a safe location (e.g., your local workstation or a network share).
Ensure the file is not corrupted by verifying its size and integrity.
Optional: Clean the Database (If Possible):
If the source database is accessible, run the VMware cleanup script to remove orphaned data, which can prevent issues during restoration:
Locate the cleanup_orphaned_data_PostgresSQL.sql script in the vCenter ISO image.
Copy it to the VCSA and run:
bash

/opt/vmware/vpostgres/current/bin/psql -U postgres -d VCDB -f /path/to/cleanup_orphaned_data_Postgres.sql
This step is optional but recommended to optimize the database.
Step 2: Deploy a New vCenter Server Appliance
Deploy a new VCSA to replace the damaged instance. Ensure the new VCSA version matches the source vCenter version to avoid schema incompatibilities.

Download the VCSA ISO:
Obtain the VCSA ISO for the same version as the source (e.g., vCenter 6.5, 6.7, or 7.0) from the VMware website.
Mount the ISO:
Mount the ISO on your workstation (Windows, Linux, or macOS) or extract its contents.
Run the Installer:
Navigate to the installer directory (e.g., vcsa-ui-installer/win32 for Windows or vcsa-ui-installer/lin64 for Linux).
Run the installer (installer.exe or ./installer).
Select Install to deploy a new VCSA instance.
Configure the New VCSA:
Follow the wizard to deploy the VCSA on an ESXi host or vCenter cluster.
Provide network details, root password, and deployment size based on your environment.
Choose the embedded Platform Services Controller (PSC) unless your original setup used an external PSC.
Complete the deployment (Stage 1) and initial configuration (Stage 2).
Verify the New VCSA:
Log in to the vSphere Client to ensure the new VCSA is operational.
Do not configure any inventory items yet, as you’ll restore the old database.
Step 3: Restore the Old Database to the New VCSA
Restoring the database to a new VCSA is not officially supported by VMware and may fail due to dependencies on other databases (e.g., SSO, licensing). Proceed with caution and test in a lab environment if possible.

Stop vCenter Services on the New VCSA:
Log in to the new VCSA via SSH as root and access the BASH shell (shell).
Stop the vCenter services to prevent database conflicts:
bash

service-control --stop --all
Transfer the Backup File:
Use WinSCP to copy the vcdb_backup.sql file to the new VCSA (e.g., to /tmp).
Access the New VCSA Database:
Retrieve the database credentials from the new VCSA’s /etc/vmware-vpx/vcdb.properties file to confirm the database name (usually VCDB) and username.
Connect to the PostgreSQL database:
bash

/opt/vmware/vpostgres/current/bin/psql -d VCDB -U postgres
Drop the Default Database (Optional):
The new VCSA creates an empty VCDB database. To avoid conflicts, you may need to drop it:
bash

DROP DATABASE VCDB;
CREATE DATABASE VCDB;
Note: This step is risky and may cause issues. Consult VMware GSS if unsure.
Restore the Database:
Exit the psql prompt (\q) and restore the database using the backup file:
bash

/opt/vmware/vpostgres/current/bin/psql -U postgres -d VCDB < /tmp/vcdb_backup.sql
This command imports the database schema and data. It may take time depending on the database size.
If errors occur, check the backup file for corruption or schema mismatches.
Verify Database Integrity:
Reconnect to the database:
bash

/opt/vmware/vpostgres/current/bin/psql -d VCDB -U postgres
List tables to confirm data restoration:
sql

\dt
Query sample data (e.g., SELECT * FROM vpx_event_partition_lookup;) to verify content.
Start vCenter Services:
Restart all services on the new VCSA:
bash

service-control --start --all
Check vCenter Functionality:
Log in to the vSphere Client and verify that the inventory, roles, permissions, and configurations from the old vCenter are restored.
Check for errors in the vCenter logs (/var/log/vmware/vpxd/vpxd.log) if issues arise.
Step 4: Post-Restoration Tasks
Reconfigure Dependencies:
If the vCenter UUID changes, re-register dependent services like Site Recovery Manager, vSphere Replication, or NSX.
Update ESXi host connections if the VCSA IP address changed.
Licensing:
Reapply licenses in the vSphere Client, as the restored database may not include licensing data.
Test the Environment:
Verify that VMs, hosts, clusters, and other objects are accessible and functional.
Test vCenter features like vMotion, HA, and DRS.
Clean Up:
Remove temporary backup files from /tmp on both VCSAs.
Delete snapshots after confirming the new VCSA is stable.
Important Notes and Risks
Unsupported Operation: VMware does not support restoring a vPostgres database to a different vCenter instance due to dependencies on other databases (e.g., SSO, licensing). This process may result in an unusable vCenter.
UUID Issues: A new VCSA generates a new UUID, which can break integrations with solutions like SRM or vRealize Operations.
Schema Compatibility: The source and target vCenter versions must match exactly, or the database schema may be incompatible.
Data Loss: If the source database is corrupted or the backup fails, you risk losing critical data. Always have multiple backups.
Consult VMware Support: Contact VMware GSS before attempting this in a production environment, as they can provide guidance or alternative solutions.
Alternative Approach: If the database restoration fails, consider deploying a new VCSA and manually reconfiguring the environment (e.g., re-adding hosts, reapplying configurations).
Troubleshooting
Database Restore Errors:
Check the backup file for completeness (less /tmp/vcdb_backup.sql).
Ensure the PostgreSQL version on the new VCSA matches the source.
vCenter Service Failures:
Review logs at /var/log/vmware/vpxd/vpxd.log for errors.
Verify database connectivity using:
bash

/opt/vmware/vpostgres/current/bin/psql -U postgres -d VCDB -c "SELECT version();"
Permission Issues:
Ensure the database user has sufficient privileges. Update credentials in vcdb.properties if needed.
UUID Conflicts:
If integrations fail, rebuild configurations for affected services (e.g., SRM, NSX).
References
VMware KB 2091961: Backup and restore vPostgres database.
VMware Documentation: Preparing PostgreSQL Database for Migration.
Broadcom Knowledge Base: Interacting with vPostgres Database.
Community Guides: Backup and restore vPostgres on VCSA.
