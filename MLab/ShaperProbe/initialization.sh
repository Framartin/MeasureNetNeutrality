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
echo "Not supported version. If any, please contact me on github (and say the name of tarballs)." > errors/version_not_supported.txt
chmod +x traitement.sh
chmod +x newtarballs.sh
mv initialization.sh initialization.sh.done    # the script is marked as done
#
####################################################################
#                  DON'T FORGET TO INSTALL gsutil                  #
#     Do not install it by the reporitories of your distribution   #
#     https://developers.google.com/storage/docs/gsutil_install    #
####################################################################
#
