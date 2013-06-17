#cd tmp
#for F in *.txt ; do tail "$F" | grep -i burst && echo "$F" ; done


cd tmp/tarballs
TARFILE=$(basename $1)    # keep only the name of the tarball
TARFILEWE=${TARFILE%.*}   # name of the tarball without the extension
# Order on the csv "IP hour minute server version upshaper downshaper upmedianrate downmedianrate" > ../../csv/$TARFILEWE.csv
IFS=$'\n'
for f in `tar f $TARFILE -t`            # trick to extract the all files on the current directory
do
    if echo $f | grep -qv "/$" ; then   # only extract files (not directories)
        echo $f
        tar f $TARFILE -x $f -O > $(basename $f)
        TXTFILE=$(basename $f)           # keep only the name of the txt file
        # tester si les fichiers ne font pas 0 octets = problème de traitement
        head $(basename $f) > shortlog.txt                # number of lines to extract needs to be determinated !!
        tail $(basename $f) >> shortlog.txt
        if ??????? shortlog.txt ; then      # check if the log is complete (ie the test was not aborded)
            if grep "aborting due to high loss rate" shortlog.txt ; then
                echo "File $f of tarball $TARFILE" >> ../../errors/high_loss_rate_logs.txt
            elif grep "Client version: 5" shortlog.txt ; then      # return the second line and check version 5
                echo "version 5 used"
                
    
                echo "\"$IP\" $HOUR $MINUTE \"$SERVER\" $VERSION \"$UPSHAPER\" \"$DOWNSHAPER\" $UPMEDIANRATE $DOWNMEDIANRATE" >> ../../csv/$TARFILEWE.csv
            elif grep "Client version: 4" shortlog.txt ; then
                echo "version 4 used"
            elif grep "Client version: 3" shortlog.txt ; then
                echo "version 3 used"
            # more version to come
            elif grep "Client version:" shortlog.txt ; then
                echo "Not supported version of ShaperProbe. Please contact me on github (and say the name of tarballs)."
                echo "File $f of tarball $TARFILE not supported" >> ../../errors/version_not_supported.txt
                # be careful : even if a version is not supported, the tarballs is marked as done
            else
                echo "This log seems to be not standard"
                echo "File $f of tarball $TARFILE not supported" >> ../../errors/non_standard_logs.txt
            fi
        fi
        rm $TXTFILE
        rm shortlog.txt
    fi
done
rm $TARFILE
cd ../..


#ou :
#find /dossier -type f -exec mv …
#shopt -s globstar ; mv **/* /cible
# solution qui peut être meilleure si on laisse les autres fichiers que *.txt pour savoir ce qui n'a pas pu être traité



# attention la forme des logs a changé avec la version du logiciel

# attention si les fichiers font plus de 1 Gio le programme ne les prendra pas
