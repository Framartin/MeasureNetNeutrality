#
#
#
date >> ./errors/update_gsutil.txt
gsutil update >& ./errors/update_gsutil.txt
date >> ./errors/latest_tarballs.txt
date >> ./errors/download_tarballs.txt
gsutil ls -R gs://m-lab/shaperprobe/** > latest_tarballs.txt 2>> ./errors/latest_tarballs.txt      # download the list of all tarballs
cat latest_tarballs.txt done_tarballs.txt > ./tmp/compare.txt
sort -u ./tmp/compare.txt       # keep only tarballs which are not already done
old_IFS=$IFS     # sauvegarde du séparateur de champ  
IFS=$'\n'        # nouveau séparateur de champ, le caractère fin de ligne
for ligne in $(cat ./tmp/compare.txt)      # download and treat new tarballs one by one
do
    echo $ligne | gsutil cp -I ./tmp/tarballs/ 2>> ./errors/download_tarballs.txt && echo $ligne >> ./tmp/downloaded_tarballs.txt && ./traitement.sh $ligne && echo $ligne >> done_tarballs.txt
done
IFS=$old_IFS

# Differences between ./tmp/downloaded_tarballs.txt and done_tarballs.txt are tarballs which failed the treatment

# If folder /tmp/tarballs is not empty after treatment, it's not normal

# vérifier que l'option -u de sort supprime bien les deux occurences des lignes en double

echo "IP hour minute server version upshaper downshaper upmedianrate downmedianrate" > data.csv    # head of the csv file
cat ./csv/*.csv >> data.csv

# Est-ce que l'on garde les fichiers csv dans csv ? Il faudra voir la place que ça prend. Si on doit les supprimer il faudra réorgniser le code différement. Mais le garder est mieux pour regénérer l'intégralité des données à chaque fois.
