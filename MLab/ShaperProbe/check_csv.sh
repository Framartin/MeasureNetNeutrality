cd csv/new
IFS=$'\n'
for CSVFILE in *.csv
do
     grep -E "^\"[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\",[0-9]{4},[0-9]{2},[0-9]{2},[0-9]{2},[0-9]{2},\"[a-zA-Z0-9\-]+\",(NA|[0-9]+),(NA|[0-9]*\.[0-9]*),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|\"no\"|[0-9]+),(NA|[0-9]+\.[0-9]+),(NA|[0-9]+\.[0-9]*)$" $CSVFILE > ../clean/$CSVFILE
     sort -o $CSVFILE.tmp $CSVFILE
     sort -o ../clean/$CSVFILE.tmp ../clean/$CSVFILE
     comm -3 $CSVFILE.tmp ../clean/$CSVFILE.tmp > ../cleaning_errors/$CSVFILE # keep the difference between the two files : lines where errors occurs
done
rm -f ../clean/*.tmp   # bug : too many arguments ?
rm -f *.tmp            # idem
exit 0
