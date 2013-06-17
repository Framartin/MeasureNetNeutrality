#cd tmp
#for F in *.txt ; do tail "$F" | grep -i burst && echo "$F" ; done


cd tmp/tarballs
TARFILE=$(basename $1)    # keep only the name of the tarball
TARFILEWE=${TARFILE%.*}   # name of the tarball without the extension
echo "IP hour minute server version upshaper downshaper upmedianrate downmedianrate" > ../../csv/$TARFILEWE.csv    # head of the csv file
IFS=$'\n'
for f in `tar f $TARFILE -t`            # trick to extract the all files on the current directory
do
    if echo $f | grep -qv "/$" ; then   # only extract files (not directories)
        echo $f
        tar f $TARFILE -x $f -O > $(basename $f)
        TXTFILE=$(basename $f)           # keep only the name of the txt file
        # tester si les fichiers ne font pas 0 octets = problème de traitement
        if sed -n '2p' $(basename $f) | grep "Client version: 5" ; then      # return the second line and check version 5
            echo "version 5 used"
        elif sed -n '2p' $(basename $f) | grep "Client version: 4" ; then
            echo "version 4 used"
        elif sed -n '2p' $(basename $f) | grep "Client version: 3" ; then
            echo "version 3 used"
        else
            echo "Not supported version. Please contact me on github (and say the name of tarballs)."
            echo "File $f of tarball $TARFILE not supported" >> ../../errors/version_not_supported.txt
            # be careful : even if a version is not supported, the tarballs is marked as done
        fi
        # traitement
        rm $TXTFILE
    fi
done
rm $TARFILE
cd ../..
# if csv/$TARFILEWE.csv ne contient qu'une ligne, le supprimer



#ou :
#find /dossier -type f -exec mv …
#shopt -s globstar ; mv **/* /cible
# solution qui peut être meilleure si on laisse les autres fichiers que *.txt pour savoir ce qui n'a pas pu être traité



# attention la forme des logs a changé avec la version du logiciel

# attention si les fichiers font plus de 1 Gio le programme ne les prendra pas
