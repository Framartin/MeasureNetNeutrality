#!/bin/bash
################################################################
#  Script used to automatically generate html files from Rmd   #
################################################################
#
# Be sure to have installed R and every necessary packages as explained in the README.md file in the Shaperprobe folder.
#
# This script is intended to be run by main.sh
#
# This script generate html files of statistical analysis of Shaperprobe's data from R Markdown source files.
# 



# generate one file pour chaque plage de dates sélectionnées

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' ../../../Databases/mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' ../../../Databases/mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' ../../../Databases/mysql.conf)

# TODO : export data in main.sh -> one CSV for each range of dates
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
SELECT Shaperprobe.ip AS ip, date_test, local_date_test, server, client_version, sleeptime, upshaper, minupburstsize, maxupburstsize, upshapingrate, downshaper, mindownburstsize, maxdownburstsize, downshapingrate, upmedianrate, downmedianrate, upcapacity, downcapacity, Shaperprobe.data_quality AS data_quality, Localisation_IP.country_code AS country_code, Localisation_IP.country_name AS country_name, As_name.as_number AS as_number, As_name.country_code AS country_code_as, Asn_to_isp_id.isp_id AS isp_id, isp_name
FROM Shaperprobe
INNER JOIN Localisation_IP ON Localisation_IP.ip = Shaperprobe.ip
INNER JOIN As_name ON As_name.ip = Shaperprobe.ip
INNER JOIN Asn_to_isp_id ON As_name.as_number = Asn_to_isp_id.as_number
INNER JOIN Isp_name ON Isp_name.isp_id = Asn_to_isp_id.isp_id ;" > data_shaperprobe.txt
EOF
sed -r 's/\t/;/g' data_shaperprobe.txt > data_shaperprobe.csv
rm data_shaperprobe.txt


