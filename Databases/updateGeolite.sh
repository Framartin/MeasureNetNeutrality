#!/bin/bash

# This script update Geolite databases. Please execute it regularly (one a week for example) on the Databases folder.

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' mysql.conf)

# download Geolite databases (IP Geolocation)
# For more information about Geolite, please visit, http://dev.maxmind.com/geoip/legacy/geolite/

wget -N -q "http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
if [ -e GeoIPCountryCSV.zip.1 ] ; then  # true if a new version was downloaded
    unzip -o GeoIPCountryCSV.zip
    mv GeoIPCountryCSV.zip.1 GeoIPCountryCSV.zip
    mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Geolite_country;
-- import lines
EOF
fi

