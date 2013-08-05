#!/bin/bash

# This script update Geolite databases. Please execute it regularly (one a week for example) on the Databases folder.
# For more information about Geolite, please visit, http://dev.maxmind.com/geoip/legacy/geolite/

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' mysql.conf)

# Update Geolite country

wget -N -q "http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
if [ -e GeoIPCountryCSV.zip.1 ] ; then  # true if a new version was downloaded
    unzip -o -j GeoIPCountryCSV.zip.1
    mv GeoIPCountryCSV.zip.1 GeoIPCountryCSV.zip
    mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Geolite_country;
-- import lines
EOF
fi

# Update Geolite city

wget -N -q "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity-latest.zip"
if [ -e GeoLiteCity-latest.zip.1 ] ; then  # true if a new version was downloaded
    unzip -o -j GeoLiteCity-latest.zip.1
    mv GeoLiteCity-latest.zip.1 GeoLiteCity-latest.zip
    mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Geolite_city_blocks;
LOAD DATA LOCAL INFILE 'GeoLiteCity-Blocks.csv'
INTO TABLE Geolite_city_blocks
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 2 LINES
(begin_ip_num, end_ip_num, loc_id);
DELETE FROM Geolite_city_location;
LOAD DATA LOCAL INFILE 'GeoLiteCity-Location.csv'
INTO TABLE Geolite_city_location
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 2 LINES
(loc_id, country_code, region_code, city_name, postal_code, latitude, longitude, metro_code, area_code);
EOF
fi

