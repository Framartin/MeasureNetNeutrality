cd csv/new
IFS=$'\n'
for CSVFILE in *.csv
do
    for line in $(cat $CSVFILE)
    do
        if ! echo "$line" | grep -E "^\"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\",[0-9]{4},[0-9]{2},[0-9]{2},[0-9]{2},[0-9]{2},\"[a-zA-Z0-9\-]+\",(NA|[0-9]+),(NA|[0-9]*\.[0-9]*),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|[0-9]+\.[0-9]+),(NA|[0-9]+\.[0-9]*)$" >/dev/null ; then
            echo "The following line of $CSVFILE is not correct" >> ../../errors/csv_not_valid.txt
            echo "$line" >> ../../errors/csv_not_valid.txt
            sed -i "/$line/ d" $CSVFILE
        fi
#        if echo "$line" | grep -Eq "" >/dev/null ; then
#            
#        fi
    done
done
