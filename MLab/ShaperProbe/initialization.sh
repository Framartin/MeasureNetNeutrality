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
mkdir results
mkdir results/by_country
mkdir results/by_country/all_data
mkdir results/by_country/last_3_months
mkdir results/by_country/last_6_months
mkdir results/by_isp
mkdir results/by_isp/all_data
mkdir results/by_isp/last_3_months
mkdir results/by_isp/last_6_months
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
    id INT UNSIGNED AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    upshaper VARCHAR(5),
    minupburstsize INT,
    maxupburstsize INT,
    upshapingrate INT,
    downshaper VARCHAR(5),
    mindownburstsize INT,
    maxdownburstsize INT,
    downshapingrate INT,
    upmedianrate INT,
    downmedianrate INT,
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    data_quality TINYINT,
    PRIMARY KEY (id),
    INDEX ind_ip (ip)
)
ENGINE=INNODB;
CREATE TABLE Shaperprobe_TMP (
    id INT UNSIGNED AUTO_INCREMENT,
    ip VARCHAR(15) NOT NULL,
    date_test DATETIME NOT NULL,
    server VARCHAR(30),
    client_version TINYINT UNSIGNED,
    sleeptime DECIMAL(4,2),
    upshaper VARCHAR(5),
    minupburstsize INT,
    maxupburstsize INT,
    upshapingrate INT,
    downshaper VARCHAR(5),
    mindownburstsize INT,
    maxdownburstsize INT,
    downshapingrate INT,
    upmedianrate INT,
    downmedianrate INT,
    upcapacity DECIMAL(10,2),
    downcapacity DECIMAL(10,2),
    data_quality TINYINT,
    PRIMARY KEY (id),
    INDEX ind_ip (ip)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_country_last_3_months (
    country_code VARCHAR(2),
    country_name VARCHAR(50),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (country_code, max_data_quality)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_country_last_6_months (
    country_code VARCHAR(2),
    country_name VARCHAR(50),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (country_code, max_data_quality)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_country_all_data (
    country_code VARCHAR(2),
    country_name VARCHAR(50),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (country_code, max_data_quality)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_isp_all_data (
    isp_name VARCHAR(50),
    country_code VARCHAR(2),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (isp_name, country_code, max_data_quality)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_isp_last_3_months (
    isp_name VARCHAR(50),
    country_code VARCHAR(2),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (isp_name, country_code, max_data_quality)
)
ENGINE=INNODB;
CREATE TABLE Results_shaperprobe_isp_last_6_months (
    isp_name VARCHAR(50),
    country_code VARCHAR(2),
    max_data_quality TINYINT, -- Variables calculated with : 2 : all data ; 1 : doubtfull + not qualified + good ; NULL : not qualified + good ; 0 : good
    up_shape_rate DECIMAL(5,3), -- percentage of ip that have an upshape (more precisely it's the mean of the mean of tests 
    down_shape_rate DECIMAL(5,3),
    up_or_down_shape_rate DECIMAL(5,3),
    up_speed_reduction_rate DECIMAL(5,3), -- percentage of the diminution of the bandwidth due to upshapes
    down_speed_reduction_rate DECIMAL(5,3),
    number_ip INT UNSIGNED,
    number_tests INT UNSIGNED,
    begin_date DATE,
    end_date DATE,
    UNIQUE INDEX ind_cc_mdq (isp_name, country_code, max_data_quality)
)
ENGINE=INNODB;
EOF
mv initialization.sh initialization.sh.done    # the script is marked as done
