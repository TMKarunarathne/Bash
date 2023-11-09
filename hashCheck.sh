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
        #echo "olhHash: $oldHash, newHash: $newHash"

        if [ "$oldHash" != "$newHash" ]; then
           echo "The file $key was changed."
            fileForHash[$key]=$newHash

            ## logger command ##
            EVENTSOURCE_IP=`hostname -I | awk '{print $1}'`
            IP=`who am i |awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip'}`
            DIR=$(pwd)
            USER=$(echo $USER)
            dir=$key
            lastModifiedTime=$(stat -c "%y" $key)
            #echo "$lastModifiedTime"
            #################################

            time="2023-11-01 18:13:10.941870738 +0530"
            stime=$(date -d "$time" "+%s")
            ms=$(echo $time | awk '{sub(/.*\./,""); print substr($1, 1, 3)}')
            mstime=$(echo "$stime.$ms")
            echo "$mstime"

            FileDir="/root/TMK/secFolder/f3"
            file=$(basename $FileDir)
            filesrch="$file\""
            logs=$(grep "$mstime.*$filesrch.*nametype=CREATE" /var/log/audit/audit.log)

            IFS=$'\n'  # Set the Internal Field Separator to newline
            for log in $logs; do
                eventID=$(echo "$log" | grep -oE 'audit\([0-9.]+:([0-9]+)' | awk -F: '{print $2}')
                syscallLog=$(grep "type=SYSCALL.*$eventID" /var/log/audit/audit.log)
                echo "$syscallLog"

                success=$(echo "$syscallLog" | grep -o 'success=[^ ]*' | awk -F'=' '{print $2}')
                command=$(echo "$syscallLog" | grep -o 'comm="[^"]*"' | sed 's/comm="//;s/"//')
                key=$(echo "$syscallLog" | grep -o 'key="[^"]*"' | sed 's/key="//;s/"//')
                action=$(echo "$syscallLog" | grep -o 'SYSCALL=[^ ]*' | awk -F'=' '{print $2}')
                auid=$(echo "$syscallLog" | grep -o 'AUID="[^"]*"' | sed 's/AUID="//;s/"//')

                # echo "Success=$success"
                # echo "Command=$command"
                # echo "Key=$key"
                # echo "Action=$action"
                # echo "AUID=$auid"
                logMes="LastModifiedTime=$lastModifiedTime, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, Success=$success, Command=$command, Key=$key, Action=$action, AUID=$auid"
                echo "$logMes"
                echo "$logMes" >> /var/log/fim.log
            done


            #################################
            #logMes="OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, LastModifiedTime=$lastModifiedTime"
            #logMes="OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="SecFolderAudit", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, LastModifiedTime=$lastModifiedTime"
            #logMes="SESSIONHISTORY=$$, USER=$USER, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, PWD=$DIR, IP=${IP}, EventType="FS", Event_Action="MODIFIED", FileDir=$dir, Hash=$newHash, LastModifiedTime=$lastModifiedTime"
            #echo "$logMes"
            #echo "$logMes" >> /var/log/fim.log
            #"$logMes" >> /var/log/fim.log
            #logger -p local6.debug -- "$logMes"

            #logger -p local6.debug -- SESSIONHISTORY=$$, USER=$USER, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, PWD=$DIR, IP=${IP}, EventType="FS", Event_Action="MODIFIED", FileDir=$dir



        fi
    done

    sleep 20
done


# Check the number of key-value pairs
#num_pairs="${#fileForHash[@]}"

# Print the number of key-value pairs
#echo "Number of key-value pairs: $num_pairs"


################################ for my ref ####################################################
# Declare an associative array
sudo timedatectl set-timezone Asia/Kolkata
declare -A key_value_pairs

# Assign values to keys
key_value_pairs["key1"]="value1"
key_value_pairs["key2"]="value2"

# Access values
echo "Value of key1: ${key_value_pairs["key1"]}"


# Pause the script for 10 seconds
sleep 10


auditctl -a always,exit -F arch=b64 -S write,open,rename,mkdir,rmdir,creat,unlink,openat,unlinkat,renameat -F dir=/root/TMK/ -F key=object_access_RUG -f 1>>/var/rug.log

#### please use the stat function 