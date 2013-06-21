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
            if grep "aborting due to high loss rate" $TXTFILE ; then
                echo "File $f of tarball $TARFILE" >> ../../errors/high_loss_rate_logs.txt
            elif grep if LINEUPSTREAM=$(grep "Upstream:" $TXTFILE) ; then echo $LINEUPSTREAM | sed ??? )
                if LINEDOWNSTREAM=$(grep "Downstream:" $TXTFILE) ; then echo $LINEDOWNSTREAM | sed ??? ) # verifier expression
                    UPMEDIANRATE=$(sed ??? $LINEUPSTREAM)
                    DOWNMEDIANRATE=$(sed ??? $LINEDOWNSTREAM)
                    IPDATE=$(echo $TXTFILE | sed -n -e 's/^\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)_\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\):\([0-9]\{2\}\).*/"\1" \2 \3 \4 \5 \6/p')    # file names are constructed the same way. This line extract the IP the date and the time from the file name
                    SERVER=$(echo $TARFILE | sed -n -e 's/^[0-9a-zA-Z]*Z-\([0-9a-zA-Z]*-[0-9a-zA-Z]*\)-shaperprobe.*/\1/p')      # extract the server name
                
                    echo $IPDATE \"$SERVER\" $VERSION \"$UPSHAPER\" \"$DOWNSHAPER\" $UPMEDIANRATE $DOWNMEDIANRATE >> ../../csv/$TARFILEWE.csv
                fi
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



# attention la forme des logs a changé avec la version du logiciel

# attention si les fichiers font plus de 1 Gio le programme ne les prendra pas
