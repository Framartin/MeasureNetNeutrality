#!/bin/bash

# This script update the AS number to ISP name mapping. Please execute it regularly (one a week for example) on the Databases folder.
# This is two csv files. Isp id are pure fictonal id used to join these two csv files (a isp can have multiple AS).
# These csv files originaly came from MLab : https://storage.cloud.google.com/?arg=m-lab#m-lab . This file is the result of parsing As_name.
# But here is a actualised and a better version manually modified by me. It's also easier to import in sql.
# IMPORTANT : if you see a improvement (duplicated, missing or out of date ISP names), please contact me, or make a pull-request on : https://github.com/Framartin/MeasureNetNeutrality

# Please don't delete isp_number_to_isp_name.csv and isp_number_to_asn.csv from the Databases folder (otherwise this script won't work properly).

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' mysql.conf)

# Update ISP id to ISP name

wget -N -q "http://raw.github.com/Framartin/MeasureNetNeutrality/master/Databases/isp_number_to_isp_name.csv"
if [ -e isp_number_to_isp_name.csv.1 ] ; then  # true if a new version was downloaded
    mv isp_number_to_isp_name.csv.1 isp_number_to_isp_name.csv
    mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Isp_name ;
LOAD DATA LOCAL INFILE 'isp_number_to_isp_name.csv'
INTO TABLE Isp_name
FIELDS TERMINATED BY ',' ENCLOSED BY ''
LINES TERMINATED BY '\n'
(isp_id, isp_name);
EOF
fi

# Update ISP id to its AS number(s)

wget -N -q "http://raw.github.com/Framartin/MeasureNetNeutrality/master/Databases/isp_number_to_asn.csv"
if [ -e isp_number_to_asn.csv.1 ] ; then  # true if a new version was downloaded
    mv isp_number_to_asn.csv.1 isp_number_to_asn.csv
    mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Asn_to_isp_id ;
LOAD DATA LOCAL INFILE 'isp_number_to_asn.csv'
INTO TABLE Asn_to_isp_id
FIELDS TERMINATED BY ',' ENCLOSED BY ''
LINES TERMINATED BY '\n'
(isp_id, as_number);
EOF
fi
