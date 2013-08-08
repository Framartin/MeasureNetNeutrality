#!/bin/bash
# check all lines of csv files in the folder csv/new/raw and copy correct lines in csv/new/clean and not correct ones in csv/new/cleaning_errors
cd csv/new/raw
IFS=$'\n'
for CSVFILE in *.csv
do
"192.33.210.16","2009-05-05 23:56:20","batch-batch",NULL,NULL,"FALSE",NULL,NULL,NULL,"FALSE",NULL,NULL,NULL,NULL,NULL,7294.83,10091.00
     grep -E "^\"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\",\"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\",\"[a-zA-Z0-9\-]+\",(NULL|[0-9]+),(NULL|[0-9]*\.[0-9]*),(\"TRUE\"|\"FALSE\"|NULL),(NULL|[0-9]+),(NULL|[0-9]+),(NULL|[0-9]+),(\"TRUE\"|\"FALSE\"|NULL),(NULL|[0-9]+),(NULL|[0-9]+),(NULL|[0-9]+),(NULL|[0-9]+),(NULL|[0-9]+),(NULL|[0-9]+\.[0-9]+),(NULL|[0-9]+\.[0-9]*)$" $CSVFILE > ../clean/$CSVFILE
     sort -o $CSVFILE.tmp $CSVFILE
     sort -o ../clean/$CSVFILE.tmp ../clean/$CSVFILE
     comm -3 $CSVFILE.tmp ../clean/$CSVFILE.tmp > ../cleaning_errors/$CSVFILE # keep the difference between the two files : lines where errors occurs
done
find ../clean/ -type f -name "*.tmp" -print0 | xargs -0 rm -f
find . -type f -name "*.tmp" -print0 | xargs -0 rm -f
exit 0
