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
# You can execute this script regulary thanks to cron, for example once a day or once a week.
#

date >> ./errors/update_gsutil.txt
gsutil update -n >& ./errors/update_gsutil.txt
date >> ./errors/latest_tarballs.txt
date >> ./errors/download_tarballs.txt
gsutil ls -R gs://m-lab/shaperprobe/** > latest_tarballs.txt 2>> ./errors/latest_tarballs.txt      # download the list of all tarballs
rm -f ./tmp/tarballs_to_do.txt
old_IFS=$IFS 
IFS=$'\n'
# put into tarballs_to_do.txt every tarballs of latest_tarballs.txt which are not in done_tarballs.txt
sort -o latest_tarballs.tmp latest_tarballs.txt
sort -o done_tarballs.tmp done_tarballs.txt
comm -3 latest_tarballs.tmp done_tarballs.tmp > ./tmp/tarballs_to_do.txt # delete line that are in both files
rm -f latest_tarballs.tmp
rm -f done_tarballs.tmp
# download the next tgz and process the current tarball at the same time
line_old=$(head -n 1 ./tmp/tarballs_to_do.txt)
echo $line_old | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $line_old >> ./tmp/downloaded_tarballs.txt # download the first tgz
for line in $(tail -n +2 ./tmp/tarballs_to_do.txt)      # download and process new tarballs one by one
do
    echo $line | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $line >> ./tmp/downloaded_tarballs.txt &   # download the next tarball
    PID1=$!
    ./process_tarball.sh $line_old && echo $line_old >> done_tarballs.txt
    wait $PID1
    line_old=$line
done
./process_tarball.sh $line_old && echo $line_old >> done_tarballs.txt  # process the last tarball
IFS=$old_IFS
rm -rf ./tmp/tarballs/files/*

# Differences between ./tmp/downloaded_tarballs.txt and done_tarballs.txt are tarballs which failed the process
# Execute : diff ./tmp/downloaded_tarballs.txt done_tarballs.txt
# The folder /tmp/tarballs should be empty after processing (except the empty sub-folder called "files")

# integrity check of new csv files
./check_csv.sh && find ./csv/new/ -name "*.csv" -type f -exec mv -f {} ./csv/not_clean/ \;  # test, make a clean version, and move csv files from new folder to not_clean folder 
# create csv with all data
echo "id,IP,date_test,server,clientversion,sleeptime,upshaper,minupburstsize,maxupburstsize,upshapingrate,downshaper,mindownburstsize,maxdownburstsize,downshapingrate,upmedianrate,downmedianrate,upcapacity,downcapacity,dataquality" > data_raw.csv    # head of the csv file
{ echo ./csv/clean/*.csv | xargs cat; } >> data_raw.csv  # prevent the "Argument list too long" bug

# POST-TREATEMENT

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)

# Team Cymru's Whois (AS Name database)
# set up the netcat whois IP querie
echo -e "begin\nnoprefix\ncountrycode\nasname\nnoregistry\nallocdate\nnotruncate\nnoheader\nasnumber" > ip_list.txt
# place the list of ip here
echo 'end' >> ip_list.txt
# netcat whois.cymru.com 43 < ip_list.txt | sort -n > as_name.raw

cd ..

