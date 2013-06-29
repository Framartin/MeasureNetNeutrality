################################################################
#                           Main script                        #
################################################################
#
#---------------------------------------------------------------------------------------------------------#
# PLEASE MAKE SURE THAT YOU HAVE ALREADY EXECUTE initialization.sh ONE (and only one) TIME BEFORE main.sh #
#---------------------------------------------------------------------------------------------------------#
#
# This script update the list of shaperprobe's tarballs, and execute treatment.sh for those which are not already done.
# To limit the size of tarballs on your hard drive, the script download, treat and remove each tarballs (marked as not done) one by one.
# You can execute this script regulary thanks to cron, for example once a day or once a week.
#
cd . # placer le bon répertoire
date >> ./errors/update_gsutil.txt
gsutil update >& ./errors/update_gsutil.txt
date >> ./errors/latest_tarballs.txt
date >> ./errors/download_tarballs.txt
gsutil ls -R gs://m-lab/shaperprobe/** > latest_tarballs.txt 2>> ./errors/latest_tarballs.txt      # download the list of all tarballs
rm ./tmp/tarballs_to_do.txt
for ligne in $(cat latest_tarballs.txt)      # put into tarballs_to_do.txt every tarballs of latest_tarballs.txt which are not in done_tarballs.txt
do
    if (! grep $ligne done_tarballs.txt) ; then
        echo $ligne >> ./tmp/tarballs_to_do.txt
    fi
done
old_IFS=$IFS     # sauvegarde du séparateur de champ  
IFS=$'\n'        # nouveau séparateur de champ, le caractère fin de ligne
for ligne in $(cat ./tmp/tarballs_to_do.txt)      # download and treat new tarballs one by one
do
    echo $ligne | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $ligne >> ./tmp/downloaded_tarballs.txt && ./treatment.sh $ligne && echo $ligne >> done_tarballs.txt
done
IFS=$old_IFS

# Differences between ./tmp/downloaded_tarballs.txt and done_tarballs.txt are tarballs which failed the treatment
# Execute : diff ./tmp/downloaded_tarballs.txt done_tarballs.txt

# The folder /tmp/tarballs should be empty after treatment

echo "IP year month day hour minute server version minupburstsize maxupburstsize upshapingrate mindownburstsize maxdownburstsize downshapingrate upmedianrate downmedianrate upcapacity downcapacity" > data.csv    # head of the csv file
cat ./csv/*.csv >> data.csv

# Est-ce que l'on garde les fichiers csv dans csv ? Il faudra voir la place que ça prend. Si on doit les supprimer il faudra réorgniser le code différement. Mais le garder est mieux pour regénérer l'intégralité des données à chaque fois.

# please note that the script is not currently taking into account the case where tarballs of more than 1 Gio are splitted into multiple tarballs of 1Gio. But this is not necessary for ShaperProbe because tarballs are small
