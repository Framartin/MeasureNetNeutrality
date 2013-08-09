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

# import new shaperprobe's tests on table Shaperprobe_TMP
mysql --local_infile=1 -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
DELETE FROM Shaperprobe_TMP;
LOAD DATA LOCAL INFILE 'data_new.csv'
INTO TABLE Shaperprobe_TMP
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(ip, date_test, server, client_version, sleeptime, upshaper, minupburstsize, maxupburstsize, upshapingrate, downshaper, mindownburstsize, maxdownburstsize, downshapingrate, upmedianrate, downmedianrate, upcapacity, downcapacity);
EOF

if [ $? -eq 0 ] ; then
    echo "data imported the $(date)" >> errors/import_data_on_sql.txt
    rm -f data_new.csv
else
    mv data_new.csv "errors/data_error_import_$(date '+%Y-%m-%d').csv"
    echo "WARNING ! Errors during the importation of data the $(date). Data stored in data_error_import_$(date '+%Y-%m-%d').csv" >> errors/import_data_on_sql.txt
fi

# Team Cymru's Whois (AS Name database)
# set up the netcat whois IP query
cd tmp
# create list of ip that are not already in As_name
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} -e "SELECT DISTINCT ip FROM Shaperprobe_TMP WHERE ip NOT IN (SELECT DISTINCT ip FROM As_name);" > ip_list.txt
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

