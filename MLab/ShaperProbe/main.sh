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
cd . # placer le bon répertoire
date >> ./errors/update_gsutil.txt
gsutil update -n >& ./errors/update_gsutil.txt
date >> ./errors/latest_tarballs.txt
date >> ./errors/download_tarballs.txt
gsutil ls -R gs://m-lab/shaperprobe/** > latest_tarballs.txt 2>> ./errors/latest_tarballs.txt      # download the list of all tarballs
rm ./tmp/tarballs_to_do.txt
old_IFS=$IFS 
IFS=$'\n'
# put into tarballs_to_do.txt every tarballs of latest_tarballs.txt which are not in done_tarballs.txt
sort -o latest_tarballs.tmp latest_tarballs.txt
sort -o done_tarballs.tmp done_tarballs.txt
comm -3 latest_tarballs.tmp done_tarballs.tmp > ./tmp/tarballs_to_do.txt # delete line that are in both files
rm latest_tarballs.tmp
rm done_tarballs.tmp
for ligne in $(cat ./tmp/tarballs_to_do.txt)      # download and treat new tarballs one by one
do
    echo $ligne | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $ligne >> ./tmp/downloaded_tarballs.txt && ./treatment.sh $ligne && echo $ligne >> done_tarballs.txt
done
IFS=$old_IFS
rm -rf ./tmp/tarballs/files/*

# Differences between ./tmp/downloaded_tarballs.txt and done_tarballs.txt are tarballs which failed the treatment
# Execute : diff ./tmp/downloaded_tarballs.txt done_tarballs.txt

# The folder /tmp/tarballs should be empty after treatment

echo "IP,year,month,day,hour,minute,server,version,sleeptime,minupburstsize,maxupburstsize,upshapingrate,mindownburstsize,maxdownburstsize,downshapingrate,upmedianrate,downmedianrate,upcapacity,downcapacity" > data.csv    # head of the csv file
cat ./csv/*.csv >> data.csv

# please note that the script is not currently taking into account the case where tarballs of more than 1 Gio are splitted into multiple tarballs of 1Gio. But this is not necessary for ShaperProbe because tarballs are small
