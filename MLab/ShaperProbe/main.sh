#!/bin/bash
################################################################
#                           Main script                        #
################################################################
#
#---------------------------------------------------------------------------------------------------------#
# PLEASE MAKE SURE THAT YOU HAVE ALREADY EXECUTED initialization.sh ONCE (and only once) BEFORE main.sh   #
#---------------------------------------------------------------------------------------------------------#
#
# Execute ONLY one instance of main.sh at the same time !
#
# This script updates the list of shaperprobe's tarballs, and executes process_tarball.sh for those which are not already done.
# To limit the size of tarballs on your hard drive, the script downloads, process and removes each tarballs (marked as not done) one by one.
# UPDATE : two tarballs are now stocked on your hard drive at a given moment to optimise speed (download of the next tarball is
#   executed in parallel of the processing of the current tarball)
# You can execute this script regulary thanks to cron, for example once a week.
#

date >> ./errors/update_gsutil.txt
gsutil update -n >& ./errors/update_gsutil.txt
date >> ./errors/latest_tarballs.txt
date >> ./errors/download_tarballs.txt
counter=0
status=1
while [ $status -ne 0 ] ; do
    gsutil ls -R gs://m-lab/shaperprobe/** > latest_tarballs.txt 2>> ./errors/latest_tarballs.txt      # download the list of all tarballs
    status=$?
    if [ $counter -gt 2 ] ; then
        exit 1
    fi
    counter=$((counter+1))
done
rm -f ./tmp/tarballs_to_do.txt
old_IFS=$IFS 
IFS=$'\n'
# put into tarballs_to_do.txt every tarballs of latest_tarballs.txt which are not in done_tarballs.txt
sort -o latest_tarballs.tmp latest_tarballs.txt
sort -o done_tarballs.tmp done_tarballs.txt
comm -23 latest_tarballs.tmp done_tarballs.tmp > ./tmp/tarballs_to_do.txt # delete lines which are in both files (and lines which are only in file done).
rm -f latest_tarballs.tmp
rm -f done_tarballs.tmp
# if no new tarballs, exit
if [ ! -s ./tmp/tarballs_to_do.txt ] ; then
    exit 0
fi
# download the next tarball and process the current tarball at the same time
line_old=$(head -n 1 ./tmp/tarballs_to_do.txt)
echo $line_old | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt ; if [ $? -eq 0 ] ; then echo $line_old >> ./tmp/downloaded_tarballs.txt ; else rm -f tmp/tarballs/$(basename $line_old) ; fi # download the first tgz
for line in $(tail -n +2 ./tmp/tarballs_to_do.txt)      # download and process new tarballs one by one
do
    ( echo $line | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt ; if [ $? -eq 0 ] ; then echo $line >> ./tmp/downloaded_tarballs.txt ; else rm -f tmp/tarballs/$(basename $line) ; fi ) &   # download the next tarball. If error occurs we delete the file, then process_tarball will end with a exit code of 1 and not mark the tarball as done
    PID1=$!
    ./process_tarball.sh $line_old && echo $line_old >> done_tarballs.txt
    wait $PID1
    line_old=$line
done
./process_tarball.sh $line_old && echo $line_old >> done_tarballs.txt  # process the last tarball
IFS=$old_IFS
rm -rf ./tmp/tarballs/files/*

# You should have no difference between tmp/downloaded_tarballs.txt and done_tarballs.txt
# Execute : diff tmp/downloaded_tarballs.txt done_tarballs.txt
# The folder /tmp/tarballs should be empty after processing (except the empty sub-folder called "files")

# integrity check of new csv files
./check_csv.sh && find ./csv/new/raw/ -name "*.csv" -type f -exec mv -f {} ./csv/all/raw/ \; && find ./csv/new/cleaning_errors/ -name "*.csv" -type f -exec mv -f {} ./csv/all/cleaning_errors/ \;  # test, make a clean version, and move csv files from new folder to not_clean folder 
# create csv with data which will be imported in table Shaperprobe_TMP
{ echo ./csv/new/clean/*.csv | xargs cat; } > data_new.csv && find ./csv/new/clean/ -name "*.csv" -type f -exec mv -f {} ./csv/all/clean/ \;
# create csv with all data
echo "IP,date_test,server,clientversion,sleeptime,upshaper,minupburstsize,maxupburstsize,upshapingrate,downshaper,mindownburstsize,maxdownburstsize,downshapingrate,upmedianrate,downmedianrate,upcapacity,downcapacity" > data_raw.csv    # head of the csv file
{ echo ./csv/all/clean/*.csv | xargs cat; } >> data_raw.csv  # prevent the "Argument list too long" bug

# POST-TREATEMENT

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)

# remove index on Shaperprobe_TMP, before importing new data
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
ALTER TABLE Shaperprobe_TMP
DROP INDEX ind_ip;
EOF

# for the importation of a lot of data, delete indexes of Shaperprobe and Localisation_IP first and recreate them after
SIZENEWDATA=$( stat -c %s data_new.csv )
if [ $SIZENEWDATA -gt 30000000 ] ; then
     mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
ALTER TABLE Shaperprobe
DROP INDEX ind_ip;
ALTER TABLE Localisation_IP
DROP INDEX ind_ip ;
ALTER TABLE Localisation_IP
DROP INDEX ind_region_code ;
ALTER TABLE Localisation_IP
DROP INDEX ind_country_code ;
ALTER TABLE Localisation_IP
DROP INDEX ind_loc_id ;
EOF
fi

# import new shaperprobe's tests on table Shaperprobe_TMP
mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Shaperprobe_TMP;
LOAD DATA LOCAL INFILE 'data_new.csv'
INTO TABLE Shaperprobe_TMP
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(ip, date_test, server, client_version, sleeptime, upshaper, minupburstsize, maxupburstsize, upshapingrate, downshaper, mindownburstsize, maxdownburstsize, downshapingrate, upmedianrate, downmedianrate, upcapacity, downcapacity) ;
EOF

if [ $? -eq 0 ] ; then
    echo "data imported the $(date)" >> errors/import_data_on_sql.txt
    rm -f data_new.csv
else
    mv data_new.csv "errors/data_error_import_$(date '+%Y-%m-%d').csv"
    echo "WARNING ! Errors during the importation of data the $(date). Data stored in data_error_import_$(date '+%Y-%m-%d').csv" >> errors/import_data_on_sql.txt
fi

# recreate index on ip for Shaperprobe_TMP
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE INDEX ind_ip
ON Shaperprobe_TMP (ip);
EOF

# Insert non located ip in Localisation_IP
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
INSERT INTO Localisation_IP
    (ip)
SELECT DISTINCT ip
FROM Shaperprobe_TMP
WHERE ip NOT IN (SELECT DISTINCT ip FROM Localisation_IP);
EOF

# recreate index of Localisation_IP if it was deleted
if [ $SIZENEWDATA -gt 30000000 ] ; then
     mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE UNIQUE INDEX ind_ip
ON Localisation_IP (ip);
EOF
fi

# Localise new ip using to Geolite databases

# add country and id of city
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
-- add the country (VERY LONG ! due to the join on a condition made by BETWEEN and not equality)
UPDATE Localisation_IP
INNER JOIN Geolite_country
    ON INET_ATON(Localisation_IP.ip) BETWEEN Geolite_country.begin_ip_num AND Geolite_country.end_ip_num
SET Localisation_IP.country_code = Geolite_country.country_code, Localisation_IP.country_name = Geolite_country.country_name
WHERE Localisation_IP.country_code IS NULL ;

-- add the id of the city (VERY LONG TOO ! due to the join on a condition made by BETWEEN and not equality)
-- need to improve speed before exectuting it
-- UPDATE Localisation_IP
-- INNER JOIN Geolite_city_blocks
--      ON INET_ATON(Localisation_IP.ip) BETWEEN Geolite_city_blocks.begin_ip_num AND Geolite_city_blocks.end_ip_num
-- SET Localisation_IP.loc_id = Geolite_city_blocks.loc_id
-- WHERE Localisation_IP.loc_id IS NULL ;
EOF

# recreate index of Localisation_IP if it was deleted
if [ $SIZENEWDATA -gt 30000000 ] ; then
     mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE INDEX ind_loc_id
ON Localisation_IP (loc_id);
EOF
fi

# Set the city name and region code for new ip
# mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
# UPDATE Localisation_IP
# INNER JOIN Geolite_city_location
#     ON Localisation_IP.loc_id = Geolite_city_location.loc_id
# SET Localisation_IP.city_name = Geolite_city_location.city_name , Localisation_IP.region_code = Geolite_city_location.region_code
# WHERE Localisation_IP.city_name IS NULL OR Localisation_IP.region_code IS NULL ;
#  -- Ajouter aussi lattitude et longitude ?
# EOF

# recreate index of Localisation_IP if it was deleted
if [ $SIZENEWDATA -gt 30000000 ] ; then
     mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE INDEX ind_region_code
ON Localisation_IP (region_code);
CREATE INDEX ind_country_code
ON Localisation_IP (country_code);
EOF
fi

# Set the region name for new ip 
# mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
# UPDATE Localisation_IP
# INNER JOIN Geolite_region_name
#      ON Localisation_IP.country_code = Geolite_region_name.country_code AND Localisation_IP.region_code = Geolite_region_name.region_code
# SET Localisation_IP.region_name = Geolite_region_name.region_name
# WHERE Localisation_IP.region_name IS NULL ;
# -- potential bug : country_code is created from geolite_country and not from geolite_city
# -- ajouter un check pour mettre à jour city si la colmun est vide ( = '' ) ; si la ville est localisée dans une verison mise à jour de Geolite_city
# -- que faire si Geolite est mis à jour : utiliser l'ancienne version ou bien tout remettre à jour
# EOF

# data qualification

# data_quality = 0 : good
#                1 : subject to doubt
#                2 : false (or absurd)
#                NULL : not qualified
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
-- mark as good, tests by ip which made more than 3 tests and that have a same results (?) (or difference under a certain rate) ; and then restrict quality to worst cases
-- TO DO : had a condtion for the convergence of results
UPDATE Shaperprobe_TMP
SET data_quality = 0
WHERE ip IN (
    SELECT DISTINCT ip
    FROM (
        SELECT ip, COUNT(*) AS nb_tests
        FROM Shaperprobe_TMP
        GROUP BY ip
        HAVING nb_tests >= 3
    ) AS ip_multi_tests
) ;
-- 250367 rows affected (1 hour 1 min 51.75 sec)

-- mark as doubtful small values of downcapacity and upcapacity, or important difference between down/upcapacity and down/upmedianrate
UPDATE Shaperprobe_TMP
SET data_quality = 1
WHERE upcapacity <= 20 OR downcapacity <= 35 OR upmedianrate <= 20 OR downmedianrate <= 35 OR upshapingrate <= 20 OR downshapingrate <= 35 OR ( downmedianrate / downcapacity ) NOT BETWEEN 1/1.5 AND 1.5 OR ( upmedianrate / upcapacity ) NOT BETWEEN 1/1.5 AND 1.5 ;

-- some data have a up/downcapacity lower than up/downshapingrate which is absurd
-- idem for up/downcapacity equal or less than 0
-- idem for very small values (upcapacity < 5 or downcapacity < 10)
UPDATE Shaperprobe_TMP
SET data_quality = 2
WHERE upcapacity <= upshapingrate OR downcapacity <= downshapingrate OR upcapacity <= 5 OR downcapacity <= 10 OR downmedianrate <= 10 OR upmedianrate <= 5 OR YEAR(date_test) < 2009 OR upmedianrate <= 5 OR downmedianrate <= 10 OR downshapingrate <= 10 OR upshapingrate <= 5 OR ( downmedianrate / downcapacity ) NOT BETWEEN 0.5 AND 2 OR ( upmedianrate / upcapacity ) NOT BETWEEN 0.5 AND 2;
EOF


# Team Cymru's Whois (AS Name database)
# set up the netcat whois IP query
cd tmp
# create list of ip that are not already in As_name
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} -e "SELECT DISTINCT ip FROM Shaperprobe_TMP WHERE ip NOT IN (SELECT DISTINCT ip FROM As_name) UNION DISTINCT SELECT DISTINCT ip FROM Shaperprobe WHERE ip NOT IN (SELECT DISTINCT ip FROM As_name) ;" > ip_list.txt   # if the query fail, these ip adress will be done next time (thanks to the union with table Shaperprobe)
if [ -s ip_list.txt ] ; then  # if there is ip not done
    echo -e "begin\nnoprefix\ncountrycode\nasname\nnoregistry\nallocdate\nnotruncate\nnoheader\nasnumber" > whois_querie.txt
    tail -n +2 ip_list.txt >> whois_querie.txt  # remove the header of ip_list
    echo 'end' >> whois_querie.txt
    netcat whois.cymru.com 43 < whois_querie.txt | sort -n > as_name.raw
    rm -f whois_querie.txt ip_list.txt
    if [ -s as_name.raw ] ; then
        sed -r 's/[\ ]{1,}\|[\ ]{1,}/|/g' as_name.raw > as_name.csv  # remove spaces between fields
        # bug if as_name is incorrect ?
        mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
LOAD DATA LOCAL INFILE 'as_name.csv'
INTO TABLE As_name
FIELDS TERMINATED BY '|' ENCLOSED BY ''
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(as_number, ip, country_code, alloc_date, as_name);
EOF
        rm -f as_name.csv
    fi
    rm -f as_name.raw
fi
cd ..

# Moving Shaperprobe_TMP on Shaperprobe
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
INSERT Shaperprobe SELECT DISTINCT * FROM Shaperprobe_TMP ;
DELETE FROM Shaperprobe_TMP ;
EOF

# recreate index of Shaperprobe if it was deleted
if [ $SIZENEWDATA -gt 30000000 ] ; then
     mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE INDEX ind_ip
ON Shaperprobe (ip);
EOF
fi

# generate result tables

# ajouter vérification sur le country code de Geolite_city identique à celui de Geolite_country
# pour la génération des résultats faire un check de l'égalité du country_code de Geolite et du Cymrus's whois (à reporter dans le data_quality)


