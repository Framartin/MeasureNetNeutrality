#!/bin/bash
#
#########################################################################################
##   EXECUTE initialization.sh ONLY THE FIRST TIME (before executing main.sh)          ##
#########################################################################################
##  INSTALL MYSQL BEFORE EXECUTING ME ! AND BE SURE TO CONFIGURE CORRECTLY mysql.conf  ##
#########################################################################################
#
#
#
####################################################################
#                  DON'T FORGET TO INSTALL gsutil                  #
#     Do not install it by the reporitories of your distribution   #
#     https://developers.google.com/storage/docs/gsutil_install    #
####################################################################
#
#
# Initialization's script :
#
mkdir errors
mkdir tmp
mkdir tmp/tarballs
mkdir tmp/tarballs/files
mkdir csv
mkdir csv/new
mkdir csv/new/raw
mkdir csv/new/clean
mkdir csv/new/cleaning_errors
mkdir csv/all
mkdir csv/all/raw
mkdir csv/all/clean
mkdir csv/all/cleaning_errors
echo "This folder contain every lines which are not correct (they are delete from the cleaning version of csv files). Names of the files are the same. You can execute a '{ echo *.csv | xargs cat; }' to see if there are errors during the treatement." > csv/all/cleaning_errors/readme.txt
touch done_tarballs.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_downstream.txt
echo "The following log files are not processed because they are not standards, but their tarballs are marked as done. This is generally normal that some appear here, because some tests are aborted (then some logs are incomplete)." > errors/non_standard_logs_no_upstream.txt
chmod +x process_tarball.sh
chmod +x main.sh
chmod +x check_csv.sh

# set variables to be able to connect to mysql
MYSQL_USER=$(sed -n -e 's/^MYSQL_USER="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_PASSWD=$(sed -n -e 's/^MYSQL_PASSWORD="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
MYSQL_DB=$(sed -n -e 's/^MYSQL_DB="\([^"]*\)"$/\1/p' ../../Databases/mysql.conf)
# create tables
mysql -u "${MYSQL_USER}" -p"${MYSQL_PASSWD}" -h localhost -D ${MYSQL_DB} <<EOF
CREATE TABLE Shaperprobe (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    upshaper VARCHAR(5),
    minupburstsize MEDIUMINT,
    maxupburstsize MEDIUMINT,
    upshapingrate MEDIUMINT,
    downshaper VARCHAR(5),
    mindownburstsize MEDIUMINT,
    maxdownburstsize MEDIUMINT,
    downshapingrate MEDIUMINT,
    upmedianrate MEDIUMINT,
    downmedianrate MEDIUMINT,
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    data_quality TINYINT,
    PRIMARY KEY (id)
)
ENGINE=INNODB;
CREATE TABLE Shaperprobe_TMP (
    id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    upshaper VARCHAR(5),
    minupburstsize MEDIUMINT,
    maxupburstsize MEDIUMINT,
    upshapingrate MEDIUMINT,
    downshaper VARCHAR(5),
    mindownburstsize MEDIUMINT,
    maxdownburstsize MEDIUMINT,
    downshapingrate MEDIUMINT,
    upmedianrate MEDIUMINT,
    downmedianrate MEDIUMINT,
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    data_quality TINYINT,
    PRIMARY KEY (id)
)
ENGINE=INNODB;
EOF
mv initialization.sh initialization.sh.done    # the script is marked as done
