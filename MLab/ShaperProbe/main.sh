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
echo "IP,year,month,day,hour,minute,server,clientversion,sleeptime,minupburstsize,maxupburstsize,upshapingrate,mindownburstsize,maxdownburstsize,downshapingrate,upmedianrate,downmedianrate,upcapacity,downcapacity" > data_raw.csv    # head of the csv file
{ echo ./csv/clean/*.csv | xargs cat; } >> data_raw.csv  # prevent the "Argument list too long" bug

# POST-TREATEMENT

# download Geolite databases (IP Geolocation)
# For more information about Geolite, please visit, http://dev.maxmind.com/geoip/legacy/geolite/
cd databases
wget -N -q "http://geolite.maxmind.com/download/geoip/database/GeoIPCountryCSV.zip"
if [ -e GeoIPCountryCSV.zip.1 ] ; then  # true if a new version was downloaded
    unzip -o GeoIPCountryCSV.zip
    mv GeoIPCountryCSV.zip.1 GeoIPCountryCSV.zip
    # delete all the lines on the mysql table and import the new csv
fi

cd ..

