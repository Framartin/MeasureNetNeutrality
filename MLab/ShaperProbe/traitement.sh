#cd tmp
#for F in *.txt ; do tail "$F" | grep -i burst && echo "$F" ; done


cd tmp/tarballs
TARFILE=$(basename $1)    # keep only the name of the tarball
IFS=$'\n'
for f in `tar f $TARFILE -t`            # trick to extract the all files on the current directory
do
    if echo $f | grep -qv "/$" ; then   # only extract files (not directories)
        echo $f
        tar f $TARFILE -x $f -O > $(basename $f)
        TXTFILE=$(basename $f)           # keep only the name of the txt file
        # tester si les fichiers ne font pas 0 octets = problème de traitement
        # traitement
        rm $TXTFILE
    fi
done
rm $TARFILE
cd ../..

#ou :
#find /dossier -type f -exec mv …
#shopt -s globstar ; mv **/* /cible




# attention la forme des logs a changé avec la version du logiciel

# attention si les fichiers font plus de 1 Gio le programme ne les prendra pas
