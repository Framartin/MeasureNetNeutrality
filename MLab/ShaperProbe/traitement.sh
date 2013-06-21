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
        TXTFILEWE=${TXTFILE%.*}          # name of the txt file without the extension
        tr -d '\0' <$TXTFILE >$TXTFILEWE.clean       # remove NULL caracter (to prevent grep to consider txt as binary files)
        # tester si les fichiers ne font pas 0 octets = problème de traitement
        head $(basename $TXTFILEWE.clean) > shortlog.txt                # number of lines to extract needs to be determinated !
            if grep "aborting due to high loss rate" $TXTFILEWE.clean ; then
                echo "File $f of tarball $TARFILE" >> ../../errors/high_loss_rate_logs.txt
            elif TEST=$(grep "Upstream:" $TXTFILEWE.clean) ; then
                echo $TEST | sed 's/???'
                IPDATE=$(echo $TXTFILE | sed -n -e 's/^\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)_\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\):\([0-9]\{2\}\).*/"\1" \2 \3 \4 \5 \6/p')    # file names seems to be constructed similary whatever client version. This line extract the IP the date and the time from the file name
                SERVER=$(echo $TARFILE | sed -n -e 's/^[0-9a-zA-Z]*Z-\([0-9a-zA-Z]*-[0-9a-zA-Z]*\)-shaperprobe.*/\1/p')
                VERSION=$()
                
                echo $IPDATE \"$SERVER\" $VERSION \"$UPSHAPER\" \"$DOWNSHAPER\" $UPMEDIANRATE $DOWNMEDIANRATE >> ../../csv/$TARFILEWE.csv
            else
                echo "This log seems to be not standard"
                echo "File $f of tarball $TARFILE not supported" >> ../../errors/non_standard_logs.txt
                # be careful : even if a file is not supported, the tarballs is marked as done
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
