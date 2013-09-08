# Database of MeasureNetNeutrality

MeasureNetNeutrality include a general database that is designed to be used for shaperprobe and other tools.
Now, this database is composed by a geolocalisation of ip adresses, a ip adresses to autonomous system (AS) map, and a AS to ISP name map.

## Initialization

Please follow these steps to be able to use this DB :

IMPORTANT NOTE : If you have already follow the installation steps of the shaperprobe's README, don't execute the following commands.

1. Install mysql-server and mysql-client
2. Create a specific user and database for MeasureNetNeutrality

For example :

    $ mysql -h localhost -u root -p
    mysql> CREATE DATABASE my_db CHARACTER SET 'utf8';
    mysql> GRANT ALL PRIVILEGES ON my_db.* TO 'my_user'@'localhost' IDENTIFIED BY 'my_password';
    mysql> quit

3. Modify mysql.conf by your own configuration of mysql
3. Please make sure that the date of your machine is correct
4. Install netcat : Use GNU's version of netcat, not nc. (nc has been known to cause buffering problems with team-cymru's server and will not always return the full output for larger IP lists). GNU netcat can be downloaded from http://netcat.sourceforge.net See the INSTALL file of netcat. (note : if you have no root priviledges, precise a folder for configure : `./configure --prefix=/home/myuser` and replace netcat command by the folder/bin/netcat)
5. execute Databases/init.sh if this is not done (only one time for all) : `$ ./init.sh  # on the Databases folder`
6. I highly recommand you to execute (thanks to cron) updateGeolite.sh and update_asn_to_isp.sh in the Databases folder. Please plan to space time between the execution of updateGeolite.sh and a script that use Geolite databases. It can take a while (~30 minutes spacing seems good).

## About geolocalisation of ip adresses

This fonctionality used Geolite's databases. They are 

8. you can now (and only now) execute main.sh : `$ ./main.sh` Be patient because it will take a lot of time... (~1.5 week on a little server, ~4 days on a good server). Please note that mysql commands will use 100% of one of your CPU's core for approx. 13 hours, this is because the join to find the country works with a between's condition and is very long).



## About ip adresses to AS map

This map used the team Cymru's Whois (AS Name database). An autonomous system is a regionnal zone in internet which have its own routing policy. The internet is composed of multiple AS. This is done to improve speed of routing : instead of routing directly to a host, a router send packets to a AS (a group of hosts).

To implement this map to your database, please see the code in the "Team Cymru's Whois (AS Name database)" section of the MLab/Shaperprobe/main.sh.

Description of mysql table As_name :
+ as_number INT UNSIGNED : the number identified the AS
+ ip VARCHAR(15) NOT NULL : the ip v4 located to the AS. This column is important to create an index and increase the speed of mysql commands.
+ country_code VARCHAR(2) : ISO country code. Becareful, for a same AS you can can have different country_code. I recommand you to do a	`GROUP BY Asn_to_isp_id.isp_id, As_name.country_code`
+ alloc_date DATE : date of allocation of the AS. Useful to have a reliable IP to ISP name map. I recommand you to use `WHERE DATE(Your_test_table.date_test) <= As_name.alloc_date`
+ as_name VARCHAR(255) : the name of the AS. You can't use it directly to have the ISP name, because 1) some ISP have multiple AS which have different names, 2) the name of the AS is never simply the name of the ISP 3) Some ISP have a commercial trade mark and a different company name
+ Index used : PRIMARY KEY (ip), INDEX ind_as_number (as_number), INDEX ind_alloc_date (alloc_date) : delete them and recreate after, if you have to import a lot of data

## About AS to ISP name map



## To do list

+ Update AS to ISP name
+ improve speed for a mysql join with a condition made by a between. Cf from lines 149 to 161 of main.sh. For the moment the localisation of a country take 13 hours on a good server (with CPU at 100%), and the city is a lot longer (more than 30 hours, maybe 73 hours). So mysql commands which need the city localisation are now commented to be not executed
+ support ip v6 (duplicate each table)

