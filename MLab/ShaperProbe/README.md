# Shaperprobe

This folder includes scripts to parse and work with the data of Shaperprobe from MeasurementLab's servers.

## Installation

Please follow these steps to be able to execute the scripts :

1. Install mysql-server and mysql-client
2. Create a specific user and database for MeasureNetNeutrality

For example :

    $ mysql -h localhost -u root -p
    mysql> CREATE DATABASE my_db CHARACTER SET 'utf8';
    mysql> GRANT ALL PRIVILEGES ON my_db.* TO 'my_user'@'localhost' IDENTIFIED BY 'my_password';
    mysql> quit
3. Make sure that the time zone table of mysql is created. Try to execute `SELECT CONVERT_TZ('2004-01-01 12:00:00','GMT','MET');` in mysql. If it return `NULL`, you have to create it : `mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql` (replace by you root username of mysql). If this table is cached, a reboot of mysql can be necessary. For more information, go to https://dev.mysql.com/doc/refman/5.5/en/time-zone-support.html
3. Modify mysql.conf by your own configuration of mysql
3. Please make sure that the date of your machine is correct
4. Install gsutil. See https://developers.google.com/storage/docs/gsutil_install : Do not install it by the reporitories of your distribution (it is an other software)
5. Install netcat : Use GNU's version of netcat, not nc. (nc has been known to cause buffering problems with team-cymru's server and will not always return the full output for larger IP lists). GNU netcat can be downloaded from http://netcat.sourceforge.net See the INSTALL file of netcat. (note : if you have no root priviledges, precise a folder for configure : `./configure --prefix=/home/myuser` and replace netcat command by the folder/bin/netcat)
6. execute initialization.sh *ONLY THIS TIME* (and NEVER after) : `$ ./initialization.sh`
7. execute Databases/init.sh if this is not done (only one time for all) : `$ ./init.sh  # on the Databases folder`
8. you can now (and only now) execute main.sh : `$ ./main.sh` Be patient because it will take a lot of time... (~1.5 week on a little server, ~4 days on a good server). Please note that mysql commands will use 100% of one of your CPU's core for approx. 13 hours, this is because the join to find the country works with a between's condition and is very long).
9. You can execute main.sh regulary thanks to cron, for example once a week. I highly recommand you to execute (also thanks to cron, before executing main.sh) updateGeolite.sh and update_asn_to_isp.sh in the Databases folder. Please plan to space time between the execution of updateGeolite.sh and main.sh. It can take a while (~30 minutes spacing seems good).

BECAREFUL : Execute ONLY one instance of main.sh at the same time !

## About Shaperprobe

Learn more about Shaperprobe on :
+ http://www.cc.gatech.edu/~partha/diffprobe/shaperprobe.html
+ http://measurementlab.net/measurement-lab-tools#shaperprobe
+ http://www.cc.gatech.edu/~partha/shaperprobe-imc11.pdf
+ http://www.cc.gatech.edu/~partha/diffprobe/

## About this script

What this script do :
- update the list of shaperprobe's tarballs
- execute process_tarball.sh for those which are not already done (download and extract tarballs, and parse each file which generate a csv file for each tarball). To limit the size of tarballs on your hard drive, the script downloads, process and removes each tarballs (marked as not done) one by one. Please note that to improve speed, download of the next tarball is executed in parallel of the processing of the current tarball. Logs of this step are stored on folder errors
- check new csv files (and moving lines which are not correct to csv/all/cleaning_errors). You can execute, on the folder csv/all/cleaning_errors, '{ echo *.csv | xargs cat; }' to see if there are errors during the treatement. A backup of each csv files before checking is stored at csv/all/raw. All csv files after the ckeck process are stored in csv/all/clean
- generate the final csv file (data_raw.csv)
- concatenate data in csv/new/clean in file data_new.csv, and import in mysql on the table Shaperprobe_TMP
- qualificate shaperprobe's tests (column data_quality = 0 : good ; 1 : subject to doubt ; 2 : false (or absurd) ; NULL : not qualified)
- localise IP thanks to Geolite's databases (find the country using Geolite country, the city and the region using Geolite city when available)
- find the Autonomous System of new ip thanks to team Cymru's Whois and then find the ISP
- generate result tables (see below to know how to use them)

A lot of new features will come soon...

## About result's tables

## About the data qualification

On the table Shaperprobe :
TO DO

On the table Result's tables by ISP :
TO DO

## To do list

+ improve speed for a mysql join with a condition made by a between. Cf from lines 149 to 161 of main.sh. For the moment the localisation of a country take 13 hours on a good server (with CPU at 100%), and the city is a lot longer (more than 30 hours, maybe 73 hours). So mysql commands which need the city localisation are now commented to be not executed

PLEASE NOTE THAT THESE SCRIPTS ARE CURRENTLY UNDER DEVELOPPEMENT
