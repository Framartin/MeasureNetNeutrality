################################################################
#                           Main script                        #
################################################################
#
#---------------------------------------------------------------------------------------------------------#
# PLEASE MAKE SURE THAT YOU HAVE ALREADY EXECUTE initialization.sh ONE (and only one) TIME BEFORE main.sh #
#---------------------------------------------------------------------------------------------------------#
#
# Execute ONLY one main.sh at the same time !
#
# This script update the list of shaperprobe's tarballs, and execute treatment.sh for those which are not already done.
# To limit the size of tarballs on your hard drive, the script download, treat and remove each tarballs (marked as not done) one by one.
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
# download the next tgz and treat the current tarball at the same time
ligne_old=$(head -n 1 ./tmp/tarballs_to_do.txt)
echo $ligne_old | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $ligne_old >> ./tmp/downloaded_tarballs.txt # download the first tgz
for ligne in $(tail -n +2 ./tmp/tarballs_to_do.txt)      # download and treat new tarballs one by one
do
    echo $ligne | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $ligne >> ./tmp/downloaded_tarballs.txt &   # download the next tarball
    PID1=$!
    ./treatment.sh $ligne_old && echo $ligne_old >> done_tarballs.txt
    wait $PID1
    ligne_old=$ligne
done
./treatment.sh $ligne_old && echo $ligne_old >> done_tarballs.txt  # treat the last tarball
IFS=$old_IFS
rm -rf ./tmp/tarballs/files/*

# Differences between ./tmp/downloaded_tarballs.txt and done_tarballs.txt are tarballs which failed the treatment
# Execute : diff ./tmp/downloaded_tarballs.txt done_tarballs.txt
# The folder /tmp/tarballs should be empty after treatment (exept the empty sub-folder called "files")

echo "IP,year,month,day,hour,minute,server,clientversion,sleeptime,minupburstsize,maxupburstsize,upshapingrate,mindownburstsize,maxdownburstsize,downshapingrate,upmedianrate,downmedianrate,upcapacity,downcapacity" > data.csv    # head of the csv file
cat ./csv/*.csv >> data.csv

