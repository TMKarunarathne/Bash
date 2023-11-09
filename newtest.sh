##### My Hash ####
declare -A fileForHash
FILELIST=`ls /root/TMK/secFolder/`

for file in $FILELIST; do
    echo "$file"
    hashFilePair=$(md5sum /root/TMK/secFolder/$file)
    #echo "$hashFilePair"
    read hash file <<< "$hashFilePair"
    echo "$file - - - -> $hash"
    fileForHash[$file]=$hash
    echo
done

############################################

i=0
while [ $i -lt 10 ]; do
    for key in "${!fileForHash[@]}"; do
        oldHash="${fileForHash[$key]}"
        read newHash p <<< $(md5sum $key)
        echo "old hash is $oldHash    ---->    new hash is $newHash"
        #echo "olhHash: $oldHash, newHash: $newHash"

        if [ "$oldHash" != "$newHash" ]; then
            echo "The file $key was changed."
            fileForHash[$key]=$newHash

            ## logger command ##
            EVENTSOURCE_IP=`hostname -I | awk '{print $1}'`
            distro=`cat /etc/os-release | grep -oP 'PRETTY_NAME="\K[^"]+'`
            IP=`who am i |awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip'}`
            dir=$key
            lastModifiedTime=$(stat -c "%y" $key)
            ###################################

            time="$lastModifiedTime"
            stime=$(date -d "$time" "+%s")
            ms=$(echo $time | awk '{sub(/.*\./,""); print substr($1, 1, 3)}')
            mstime=$(echo "$stime.$ms")
            #echo "$mstime"

            FileDir="$dir"
            file=$(basename $FileDir)
            filesrch="$file\""
            logs=$(grep "$mstime.*$filesrch.*nametype=CREATE" /var/log/audit/audit.log)

            IFS=$'\n'  # Set the Internal Field Separator to newline
            # for log in $logs; do
            #     eventID=$(echo "$log" | grep -oE 'audit\([0-9.]+:([0-9]+)' | awk -F: '{print $2}')
            #     syscallLog=$(grep "type=SYSCALL.*$eventID" /var/log/audit/audit.log)
            #     echo "$syscallLog"

            #     success=$(echo "$syscallLog" | grep -o 'success=[^ ]*' | awk -F'=' '{print $2}')
            #     command=$(echo "$syscallLog" | grep -o 'comm="[^"]*"' | sed 's/comm="//;s/"//')
            #     keyWord=$(echo "$syscallLog" | grep -o 'key="[^"]*"' | sed 's/key="//;s/"//')
            #     action=$(echo "$syscallLog" | grep -o 'SYSCALL=[^ ]*' | awk -F'=' '{print $2}')
            #     auid=$(echo "$syscallLog" | grep -o 'AUID="[^"]*"' | sed 's/AUID="//;s/"//')

            #     logMes="LastModifiedTime=$lastModifiedTime, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, Success=$success, Command=$command, Key=$keyWord, Action=$action, AUID=$auid"
            #     echo "$logMes"
            #     echo "$logMes" >> /var/log/fim.log
            # done

            ###################################
            logMes="OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, LastModifiedTime=$lastModifiedTime"

            echo "$logMes"
            echo "$logMes" >> /var/log/fim.log



        fi
    done
    echo " "
    sleep 5
done
