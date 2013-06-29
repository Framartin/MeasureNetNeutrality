#
#########################################################################################
##   EXECUTE initialization.sh ONLY THE FIRST TIME (before executing newtarballs.sh)   ##
#########################################################################################
#
# Initialization's script :
#
mkdir errors
mkdir tmp
mkdir tmp/tarballs
mkdir csv
touch done_tarballs.txt
echo "DO NOT DELETE THIS FILE (you will need it to include theses logs in csv)" >> errors/version_not_supported.txt
echo "The following log files are not treated because they are not standards, but theyr tarballs are marked as done. This is generally normal that some appears here, because some tests seems to be aborded by the user (then log are incomplete)." > errors/non_standard_logs.txt
chmod +x treatment.sh
chmod +x main.sh
mv initialization.sh initialization.sh.done    # the script is marked as done
#
####################################################################
#                  DON'T FORGET TO INSTALL gsutil                  #
#     Do not install it by the reporitories of your distribution   #
#     https://developers.google.com/storage/docs/gsutil_install    #
####################################################################
#
