cd tmp/tarballs
TARFILE=$(basename $1)    # keep only the name of the tarball
TARFILEWE=${TARFILE%.*}   # name of the tarball without the extension
IFS=$'\n'
for f in `tar f $TARFILE -t`            # trick to extract the all files on the current directory
do
    if echo $f | grep -qv "/$" ; then   # only extract files (not directories)
        echo $f
        tar f $TARFILE -x $f -O > $(basename $f)
        TXTFILE=$(basename $f)           # keep only the name of the txt file
        TXTFILEWE=${TXTFILE%.*}          # name of the txt file without the extension
        tr -d '\0' <$TXTFILE >$TXTFILEWE.clean       # remove NULL character (to prevent grep to consider txt as binary files)
        IPDATE="NA NA NA NA NA NA"
        SLEEPTIME="NA"
        SERVER="NA"
        VERSION="NA"
        UPSHAPER="NA NA NA"
        DOWNSHAPER="NA NA NA"
        UPMEDIANRATE="NA"
        DOWNMEDIANRATE="NA"
        UPCAPACITY="NA"
        DOWNCAPACITY="NA"
        SIZEFILE=$(ls -l $TXTFILEWE.clean | awk '{print $5}')    # test if the size of the file is greater than 0
        if [ $SIZEFILE -gt 0 ] ; then
            if grep "aborting due to high loss rate" $TXTFILEWE.clean >/dev/null ; then
                echo "File $f of tarball $TARFILE" >> ../../errors/high_loss_rate_logs.txt
            elif UPSTREAMLINE=$(grep "Upstream:" $TXTFILEWE.clean) ; then
                if echo $ $UPSTREAMLINE | grep "No shaper detected" >/dev/null ; then
                    UPSHAPER="\"no\" \"no\" \"no\""
                    LINENUMBER=$(grep -n "Upstream:" $TXTFILEWE.clean | cut -d: -f1)   # if no shaper is detected, the next line CAN contain the median received rate
                    LINENUMBER=$((LINENUMBER+1))
                    UPMEDIANRATELINE=$(awk "NR==$LINENUMBER" $TXTFILEWE.clean)                            # extract this line
                    if echo $UPMEDIANRATELINE | grep "Median received rate" >/dev/null ; then   # test if this line contain the rate
                        UPMEDIANRATE=$(echo $UPMEDIANRATELINE | sed -n -e 's/^Median received rate. \([0-9]*\) [KkBbPpSs]*.*/\1/p')   #extract the median recieved rate
                    fi
                elif echo $UPSTREAMLINE | grep -E "^Upstream. Burst size. [0-9]* [KkBb]*" >/dev/null ; then
                        UPSHAPER=$(echo $DOWNSTREAMLINE | sed -n -e 's/^Upstream: Burst size: \([0-9]*\) [KkBb]*; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \1 \2/p')
                        UPMEDIANRATE="\"no\""
                elif echo $UPSTREAMLINE | grep -E "^Upstream. Burst size. [0-9]*-[0-9]* [KkBb]*" >/dev/null ; then
                        UPSHAPER=$(echo $UPSTREAMLINE | sed -n -e 's/^Upstream: Burst size: \([0-9]*\)-\([0-9]*\) [KkBb]*; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \2 \3/p')
                        UPMEDIANRATE="\"no\""
                else
                    echo "The syntax of this log is not supported (no classic Upstream)"
                    echo "Syntax of $f of tarball $TARFILE not supported (no classic Upstream)" >> ../../errors/non_supported_syntax_upstream.txt
                    echo "This is not normal. Contact me on github if happen." >> ../../errors/non_supported_syntax_downstream.txt
                    # be careful : even if a file is not supported, the tarballs is marked as done
                fi
                if DOWNSTREAMLINE=$(grep "Downstream:" $TXTFILEWE.clean) ; then
                    if echo $DOWNSTREAMLINE | grep "No shaper detected" >/dev/null ; then
                        DOWNSHAPER="\"no\" \"no\" \"no\""
                        LINENUMBER=$(grep -n "Downstream:" $TXTFILEWE.clean | cut -d: -f1)   # if no shaper is detected, the following line CAN contain the median received rate
                        LINENUMBER=$((LINENUMBER+1))
                        DOWNMEDIANRATELINE=$(awk "NR==$LINENUMBER" $TXTFILEWE.clean)         # extract this line
                        if echo $DOWNMEDIANRATELINE | grep "Median received rate" >/dev/null ; then         # test if this line contain the rate
                            DOWNMEDIANRATE=$(echo $DOWNMEDIANRATELINE | sed -n -e 's/^Median received rate. \([0-9]*\) [KkBbPpSs]*.*/\1/p')   #extract the median recieved rate
                        fi
                    elif echo $DOWNSTREAMLINE | grep -E "^Downstream. Burst size. [0-9]* [KkBb]*" >/dev/null ; then
                        DOWNSHAPER=$(echo $DOWNSTREAMLINE | sed -n -e 's/^Downstream: Burst size: \([0-9]*\) [KkBb]*; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \1 \2/p')
                        DOWNMEDIANRATE="\"no\""
                    elif echo $DOWNSTREAMLINE | grep -E "^Downstream. Burst size. [0-9]*-[0-9]* [KkBb]*" >/dev/null ; then
                        DOWNSHAPER=$(echo $DOWNSTREAMLINE | sed -n -e 's/^Downstream: Burst size: \([0-9]*\)-\([0-9]*\) [KkBb]*; Shaping rate: \([0-9]*\) [KkBbPpSs]*.*/\1 \2 \3/p')
                        DOWNMEDIANRATE="\"no\""
                    else
                        echo "The syntax of this log is not supported (no classic Downstream)"
                        echo "Syntax of $f of tarball $TARFILE not supported (no classic Downstream)" >> ../../errors/non_supported_syntax_downstream.txt
                        echo "This is not normal. Contact me on github if happen." >> ../../errors/non_supported_syntax_downstream.txt
                    fi
                    if UPCAPACITYLINE=$(grep "upstream capacity" $TXTFILEWE.clean) ; then          # extract the upstream capacity (in Kbps)
                        UPCAPACITY=$(echo $UPCAPACITYLINE | sed -n -e 's/^upstream capacity. \([0-9]*\.[0-9]*\) [KkBbPpSs]*.*/\1/p')
                    fi
                    if DOWNCAPACITYLINE=$(grep "downstream capacity" $TXTFILEWE.clean) ; then          # extract the downstream capacity (in Kbps)
                        DOWNCAPACITY=$(echo $DOWNCAPACITYLINE | sed -n -e 's/^downstream capacity. \([0-9]*\.[0-9]*\) [KkBbPpSs]*.*/\1/p')
                    fi
                    IPDATE=$(echo $TXTFILE | sed -n -e 's/^\([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\)_\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9]\{2\}\):\([0-9]\{2\}\).*/"\1" \2 \3 \4 \5 \6/p')    # file names seems to be constructed similary whatever client version. This line extract the IP the date and the time from the file name
                    SERVER=$(echo $TARFILE | sed -n -e 's/^[0-9a-zA-Z]*Z-\([0-9a-zA-Z]*-[0-9a-zA-Z]*\)-shaperprobe.*/\1/p') # Extract server name from the name of the tarball
                    head -n 3 $TXTFILEWE.clean > headlog.tmp       # save head of the file
                    if SLEEPTIMELINE=$(grep "sleep time resolution" headlog.tmp) ; then          # extract the sleep time resolution (in ms)
                        SLEEPTIME=$(echo $SLEEPTIMELINE | sed -n -e 's/^sleep time resolution. \([0-9]*\.[0-9]*\) [MmSs]*.*/\1/p')
                    fi
                    if VERSIONLINE=$(grep "Client version" headlog.tmp) ; then                   # extract the client version
                        VERSION=$(echo $VERSIONLINE | sed -n -e 's/^Client version. \([0-9]*\).*/\1/p')
                    fi
                    echo $IPDATE \"$SERVER\" $VERSION $SLEEPTIME $UPSHAPER $DOWNSHAPER $UPMEDIANRATE $DOWNMEDIANRATE $UPCAPACITY $DOWNCAPACITY >> ../../csv/$TARFILEWE.csv # attention mettre des virgules en séparation.
                else
                    echo "The syntax of this log is not supported (no Downstream)"
                    echo "Syntax of $f of tarball $TARFILE not supported (no Down Downstream)" >> ../../errors/non_standard_logs_no_downstream.txt
                    # be careful : even if a file is not supported, the tarballs is marked as done
                    # Please contact me (Framartin on GitHub) if any.
                fi
            else
                echo "This log seems to be not standard (no Upstream)"
                echo "File $f of tarball $TARFILE not supported (no Upstream)" >> ../../errors/non_standard_logs_no_upstream.txt
                #cp $TXTFILEWE.clean ../../errors/tarballs-non-standard     # Decomment if you want to keep a copy of non standard logs. BEFORE execute : mkdir errors/tarballs-non-standard
                # be careful : even if a file is not supported, the tarballs is marked as done
            fi
        else
            echo "File $f of tarball $TARFILE is empty" >> ../../errors/empty_logs.txt
        fi
        rm $TXTFILE
        rm $TXTFILEWE.clean
    fi
done
rm $TARFILE
rm headlog.tmp
cd ../..
