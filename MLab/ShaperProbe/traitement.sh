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
        tr -d '\0' <$TXTFILE >$TXTFILEWE.clean       # remove NULL character (to prevent grep to consider txt as binary files)
        $IPDATE="NA NA NA NA NA NA"
        $SERVER="NA"
        $VERSION="NA"
        $UPSHAPER="NA NA NA"
        $DOWNSHAPER="NA NA NA"
        $UPMEDIANRATE="NA"
        $DOWNMEDIANRATE="NA"
        # tester si les fichiers ne font pas 0 octets = problème de traitement
            if grep "aborting due to high loss rate" $TXTFILEWE.clean ; then
                echo "File $f of tarball $TARFILE" >> ../../errors/high_loss_rate_logs.txt
            elif UPSTREAMLINE=$(grep "Upstream:" $TXTFILEWE.clean) ; then
                if grep "No shaper detected" $UPSTREAMLINE ; then
                    UPSHAPER="\"N\" \"N\" \"N\""
                elif grep "Burst size:" $UPSTREAMLINE ; then
                    UPSHAPER=$(echo $UPSTREAMLINE | sed -n -e 's/^Upstream: Burst size: \([0-9]*\)-\([0-9]*\) [Kk][Bb]; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \2 \3/p')
                else
                    echo "The syntax of this log is not supported (no Up Burst)"
                    echo "Syntax of $f of tarball $TARFILE not supported (no Up Burst)" >> ../../errors/non_supported_syntax.txt
                    # be careful : even if a file is not supported, the tarballs is marked as done
                    # Please contact me (Framartin on GitHub) if any.
                fi
                if DOWNSTREAMLINE=$(grep "Downstream:" $TXTFILEWE.clean) ; then
                if grep "No shaper detected" $DOWNSTREAMLINE ; then
                    DOWNSHAPER="\"N\" \"N\" \"N\""
                elif grep "Burst size:" $DOWNSTREAMLINE ; then
                    DOWNSHAPER=$(echo $DOWNSTREAMLINE | sed -n -e 's/^Downstream: Burst size: \([0-9]*\)-\([0-9]*\) [Kk][Bb]; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \2 \3/p')
                # BUG : Two types if log. Some with a interval and some with only one value.
                # Downstream: Burst size: 3696-4886 KB; Shaping rate: 5077 Kbps.
                # Downstream: Burst size: 11755 KB; Shaping rate: 6272 Kbps.

                else
                    echo "The syntax of this log is not supported (no Down Burst)"
                    echo "Syntax of $f of tarball $TARFILE not supported (no Down Burst)" >> ../../errors/non_supported_syntax.txt
                    # be careful : even if a file is not supported, the tarballs is marked as done
                    # Please contact me (Framartin on GitHub) if any.
                fi
                IPDATE=$(echo $TXTFILE | sed -n -e 's/^\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)_\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\):\([0-9]\{2\}\).*/"\1" \2 \3 \4 \5 \6/p')    # file names seems to be constructed similary whatever client version. This line extract the IP the date and the time from the file name
                SERVER=$(echo $TARFILE | sed -n -e 's/^[0-9a-zA-Z]*Z-\([0-9a-zA-Z]*-[0-9a-zA-Z]*\)-shaperprobe.*/\1/p') # Extract server name from the name of the tarball
                VERSION=$(head $(basename $TXTFILEWE.clean))
                
                echo $IPDATE \"$SERVER\" $VERSION $UPSHAPER $DOWNSHAPER $UPMEDIANRATE $DOWNMEDIANRATE >> ../../csv/$TARFILEWE.csv # attention mettre des virgules en séparation.
            else
                echo "This log seems to be not standard (no Upstream)"
                echo "File $f of tarball $TARFILE not supported (no Upstream)" >> ../../errors/non_standard_logs.txt
                # be careful : even if a file is not supported, the tarballs is marked as done
            fi
        fi
        rm $TXTFILE
    fi
done
rm $TARFILE
cd ../..


#ou :
#find /dossier -type f -exec mv …
#shopt -s globstar ; mv **/* /cible
# solution qui peut être meilleure si on laisse les autres fichiers que *.txt pour savoir ce qui n'a pas pu être traité
