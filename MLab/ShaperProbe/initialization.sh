#!/bin/bash
#
#########################################################################################
##   EXECUTE initialization.sh ONLY THE FIRST TIME (before executing main.sh)          ##
#########################################################################################
##  INSTALL MYSQL BEFORE EXECUTING ME ! AND BE SURE TO CONFIGURE CORRECTLY mysql.conf  ##
#########################################################################################
#
#
#
####################################################################
#                  DON'T FORGET TO INSTALL gsutil                  #
#     Do not install it by the reporitories of your distribution   #
#     https://developers.google.com/storage/docs/gsutil_install    #
####################################################################
#
#
# Initialization's script :
#
mkdir errors
mkdir tmp
mkdir tmp/tarballs
mkdir tmp/tarballs/files
mkdir csv
mkdir csv/new
mkdir csv/clean
mkdir csv/not_clean
mkdir csv/cleaning_errors
mkdir databases
echo "This folder contain every lines which are not correct (they are delete from the cleaning version of csv files). Names of the files are the same. You can execute a '{ echo *.csv | xargs cat; }' to see if there are errors during the treatement." > csv/cleaning_errors/readme.txt
touch done_tarballs.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_downstream.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_upstream.txt
chmod +x process_tarball.sh
chmod +x main.sh
chmod +x check_csv.sh

#download databases
cd databases
wget -q "http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
if [ -e GeoIPCountryCSV.zip ] ; then
     unzip GeoIPCountryCSV.zip
else
     echo 'WARNING ! DOWNLOAD OF GEOLITE COUNTRY FAIL ! Please manually download it !'
     echo 'Execute on folder databases : wget http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip '
fi

cd ..

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' mysql.conf)
# create tables
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE TABLE Shaperprobe (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    minupburstsize VARCHAR(8), -- need to be changed to INT
    maxupburstsize VARCHAR(8), -- need to be changed to INT
    upshapingrate VARCHAR(8), -- need to be changed to INT
    mindownburstsize VARCHAR(8), -- need to be changed to INT
    maxdownburstsize VARCHAR(8), -- need to be changed to INT
    downshapingrate VARCHAR(8), -- need to be changed to INT
    upmedianrate VARCHAR(8), -- need to be changed to INT
    downmedianrate VARCHAR(8), -- need to be changed to INT
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    upshape VARCHAR(5), -- attention vérifier qu'il est bien dans le csv ; 'TRUE' or 'FALSE'
    downshape VARCHAR(5), -- attention vérifier qu'il est bien dans le csv ; 'TRUE' or 'FALSE'
    data_quality TINYINT UNSIGNED, -- attention vérifier qu'il est bien dans le csv ;
    PRIMARY KEY (id)
)
ENGINE=INNODB;
CREATE TABLE Shaperprobe_TMP (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    minupburstsize VARCHAR(8), -- need to be changed to INT
    maxupburstsize VARCHAR(8), -- need to be changed to INT
    upshapingrate VARCHAR(8), -- need to be changed to INT
    mindownburstsize VARCHAR(8), -- need to be changed to INT
    maxdownburstsize VARCHAR(8), -- need to be changed to INT
    downshapingrate VARCHAR(8), -- need to be changed to INT
    upmedianrate VARCHAR(8), -- need to be changed to INT
    downmedianrate VARCHAR(8), -- need to be changed to INT
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    upshape VARCHAR(5), -- attention vérifier qu'il est bien dans le csv ; 'TRUE' or 'FALSE'
    downshape VARCHAR(5), -- attention vérifier qu'il est bien dans le csv ; 'TRUE' or 'FALSE'
    data_quality TINYINT UNSIGNED, -- attention vérifier qu'il est bien dans le csv ;
    PRIMARY KEY (id)
)
ENGINE=INNODB;
CREATE TABLE Localisation_IP (
    ip VARCHAR(15) NOT NULL,
    country_code VARCHAR(2),
    country_name VARCHAR(50),
    loc_id MEDIUMINT UNSIGNED NOT NULL, -- city code
    city_name VARCHAR(255),
    region_code VARCHAR(2),
    region_name VARCHAR(50),
    PRIMARY KEY (ip)
)
ENGINE=INNODB;
CREATE TABLE Geolite_country (
    begin_ip VARCHAR(15),
    end_ip VARCHAR(15),
    begin_ip_num INT UNSIGNED,
    end_ip_num INT UNSIGNED,
    country_code VARCHAR(2),
    country_name VARCHAR(50)
)
ENGINE=INNODB;
CREATE TABLE Geolite_region_code (
    country_code VARCHAR(2),
    region_code VARCHAR(2),
    region_name VARCHAR(50)
)
ENGINE=INNODB;
CREATE TABLE Geolite_city_blocks (
    begin_ip_num INT UNSIGNED NOT NULL,
    end_ip_num INT UNSIGNED NOT NULL,
    loc_id MEDIUMINT UNSIGNED NOT NULL,
)
ENGINE=INNODB;
CREATE TABLE Geolite_city_location (
    loc_id MEDIUMINT UNSIGNED NOT NULL,
    country_code VARCHAR(2),
    region_code CHAR(2),
    city_name VARCHAR(255),
    postal_code VARCHAR(6),
    latitude DECIMAL(7,4),
    longitude DECIMAL(7,4),
    metro_code SMALLINT UNSIGNED,
    area_code char(3),
    PRIMARY KEY (loc_id)
)
ENGINE=INNODB;
-- CREATE TABLE As_name (
--    ip VARCHAR(15) NOT NULL,
--    asn,
--    allocated,
--    country_code,
-- )
-- ENGINE=INNODB;
EOF
mv initialization.sh initialization.sh.done    # the script is marked as done

