#
#########################################################################################
##   EXECUTE initialization.sh ONLY THE FIRST TIME (before executing main.sh)          ##
#########################################################################################
#
# Initialization's script :
#
mkdir errors
mkdir tmp
mkdir tmp/tarballs
mkdir tmp/tarballs/files
mkdir csv
mkdir csv/new
mkdir csv/clean
mkdir csv/not_clean
mkdir csv/cleaning_errors
echo "This folder contain every lines which are not correct (they are delete from the cleaning version of csv files). Names of the files are the same. You can execute a '{ echo *.csv | xargs cat; }' to see if there are errors during the treatement." > csv/cleaning_errors/readme.txt
touch done_tarballs.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_downstream.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_upstream.txt
chmod +x process_tarball.sh
chmod +x main.sh
chmod +x check_csv.sh
mv initialization.sh initialization.sh.done    # the script is marked as done
#
####################################################################
#                  DON'T FORGET TO INSTALL gsutil                  #
#     Do not install it by the reporitories of your distribution   #
#     https://developers.google.com/storage/docs/gsutil_install    #
####################################################################
#
