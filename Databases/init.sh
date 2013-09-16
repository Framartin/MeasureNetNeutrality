#!/bin/bash
#
#########################################################################################
##          EXECUTE init.sh ONLY THE FIRST TIME (before executing main.sh)             ##
#########################################################################################
##  INSTALL MYSQL BEFORE EXECUTING ME ! AND BE SURE TO CONFIGURE CORRECTLY mysql.conf  ##
#########################################################################################
#
#

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' mysql.conf)

mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE TABLE Localisation_IP (
    ip VARCHAR(15) NOT NULL,
    country_code VARCHAR(2),
    country_name VARCHAR(50),
    loc_id MEDIUMINT UNSIGNED, -- city code
    city_name VARCHAR(255),
    region_code VARCHAR(2),
    region_name VARCHAR(50),
    data_quality TINYINT,
    UNIQUE INDEX ind_ip (ip),
    INDEX ind_region_code (region_code),
    INDEX ind_country_code (country_code),
    INDEX ind_loc_id (loc_id)
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
CREATE TABLE Geolite_region_name (
    country_code VARCHAR(2) NOT NULL,
    region_code CHAR(2) NOT NULL,
    region_name VARCHAR(50),
    INDEX ind_country_code (country_code),
    INDEX ind_region_code (region_code)
)
ENGINE=INNODB;
CREATE TABLE Geolite_city_blocks (
    begin_ip_num INT UNSIGNED NOT NULL,
    end_ip_num INT UNSIGNED NOT NULL,
    loc_id MEDIUMINT UNSIGNED NOT NULL,
    PRIMARY KEY (begin_ip_num)
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
CREATE TABLE As_name (
    as_number INT UNSIGNED,
    ip VARCHAR(15) NOT NULL,
    country_code VARCHAR(2),
    alloc_date DATE,
    as_name VARCHAR(255),
    PRIMARY KEY (ip),
    INDEX ind_as_number (as_number),
    INDEX ind_alloc_date (alloc_date)
)
ENGINE=INNODB;
CREATE TABLE Isp_name (
    isp_id INT UNSIGNED NOT NULL,
    isp_name VARCHAR(255),
    PRIMARY KEY (isp_id)
)
ENGINE=INNODB;
CREATE TABLE Asn_to_isp_id (
    isp_id INT UNSIGNED NOT NULL,
    as_number INT UNSIGNED NOT NULL,
    PRIMARY KEY (as_number),
    INDEX ind_isp_id (isp_id)
)
ENGINE=INNODB;
CREATE TABLE Country_time_zone (
    id INT UNSIGNED NOT NULL,
    country_code VARCHAR(2),
    country_code_3 VARCHAR(2),
    country_name VARCHAR(50),
    latitude DECIMAL(7,4),
    longitude DECIMAL(7,4),
    currency VARCHAR(20),
    timezone VARCHAR(50),
    PRIMARY KEY (id),
    INDEX ind_cc (country_code)
)
ENGINE=INNODB;
EOF

#download and import databases
# Geolite Country
wget -q "http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
if [ -e GeoIPCountryCSV.zip ] ; then
     unzip -j GeoIPCountryCSV.zip
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'GeoIPCountryWhois.csv'
INTO TABLE Geolite_country
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(begin_ip, end_ip, begin_ip_num, end_ip_num, country_code, country_name);
-- create index after importing data
CREATE UNIQUE INDEX ind_ip_num
ON Geolite_country (begin_ip_num, end_ip_num);
CREATE INDEX ind_end_ip_num
ON Geolite_country (end_ip_num);
EOF
else
     echo 'WARNING ! DOWNLOAD OF GEOLITE COUNTRY FAIL ! Please manually download it !'
     echo 'Execute on folder Databases : wget http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip '
fi

# Geolite City

wget -q "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity-latest.zip"
if [ -e GeoLiteCity-latest.zip ] ; then
     unzip -j GeoLiteCity-latest.zip
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'GeoLiteCity-Blocks.csv'
INTO TABLE Geolite_city_blocks
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 2 LINES
(begin_ip_num, end_ip_num, loc_id);
LOAD DATA LOCAL INFILE 'GeoLiteCity-Location.csv'
INTO TABLE Geolite_city_location
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 2 LINES
(loc_id, country_code, region_code, city_name, postal_code, latitude, longitude, metro_code, area_code);
EOF
else
     echo 'WARNING ! DOWNLOAD OF GEOLITE CITY FAIL ! Please manually download it !'
     echo 'Execute on folder Databases : wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity-latest.zip '
fi

# Geolite Region Name

wget -q "http://dev.maxmind.com/static/csv/codes/maxmind/region.csv"
if [ -e region.csv ] ; then
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'region.csv'
INTO TABLE Geolite_region_name
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(country_code, region_code, region_name);
EOF
else
     echo 'WARNING ! DOWNLOAD OF GEOLITE REGION NAME FAIL ! Please manually download it !'
     echo 'Execute on folder Databases : wget http://dev.maxmind.com/static/csv/codes/maxmind/region.csv '
fi

# TEMPORARY SOLUTION TO MAP AS number to ISP
# Find dynamic solution which is always up-to-date

if [ -e isp_number_to_asn.csv ] ; then
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'isp_number_to_asn.csv'
INTO TABLE Asn_to_isp_id
FIELDS TERMINATED BY ',' ENCLOSED BY ''
LINES TERMINATED BY '\n'
(isp_id, as_number);
EOF
else
     echo 'WARNING ! The csv file isp_number_to_asn.csv is not imported in mysql, please download it !'
fi

if [ -e isp_number_to_isp_name.csv ] ; then
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'isp_number_to_isp_name.csv'
INTO TABLE Isp_name
FIELDS TERMINATED BY ',' ENCLOSED BY ''
LINES TERMINATED BY '\n'
(isp_id, isp_name);
EOF
else
     echo 'WARNING ! The csv file isp_number_to_isp_name.csv is not imported in mysql, please download it !'
fi

# Use a country to olson timezone map to be able to compute local time of tests
# Since we have not acess to region of test, we will find an approximative time zone (some countries are in multiple time zones).
# For more information about csv file, please visit : http://mayavps.com/articles/download-free-iso-codes-and-exchange-rates/

wget -q "http://mayavps.com/download/18/countries.csv"
if [ -e region.csv ] ; then
     mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'countries.csv'
INTO TABLE Country_time_zone
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 2 LINES
(id, country_code, country_code_3, country_name, latitude, longitude, currency, timezone);
EOF
else
     echo 'WARNING ! DOWNLOAD OF COUNTRY TO TIME ZONE FAILS ! Please manually download it !'
     echo 'Execute on folder Databases : wget http://mayavps.com/download/18/countries.csv '
fi

mv init.sh init.sh.done
