##### My Hash ####
###########################################
# FILELIST=`ls /root/TMK/secFolder/`
FileListUpdate(){
    # FILELIST=`ls $1`
    FILELIST=`ls /root/TMK/secFolder/`

    for file in $FILELIST; do
        echo "$file"
        hashFilePair=$(md5sum /root/TMK/secFolder/$file)
        #echo "$hashFilePair"
        read hash file <<< "$hashFilePair"
        echo "$file - - - -> $hash"
        fileForHash[$file]=$hash
        #echo
    done
}
###########################################
FileListCheck(){
    shouldUpdate=false
    unset IFS
    # FILELIST=`ls $1`
    FILELIST=`ls /root/TMK/secFolder/`

    for key in "${!fileForHash[@]}"; do
        oldHash="${fileForHash[$key]}"

        if [[ -e $key ]]; then
            echo "$key file exists."
        else
            echo "$key file does not exist. It was removed/deleted"
            shouldUpdate=true
            deletedFiles[$key]=$oldHash
            newHash=$oldHash
            output_file="/root/TMK/imp/deletedFiles.txt"
            # Loop through the array and write its contents to the file
            lastModifiedTime=$(date) 
            echo -e "File: $key, \tHash: $oldHash, \tNoticedTime: $lastModifiedTime" >> "$output_file"

            ## logger command ##
            eventAction="DELETED"
            miniLogCreator
            ################
            FileDir="$key"
            file=$(basename $FileDir)
            filesrch="/$file\""

            logs=$(grep "$filesrch.*nametype=DELETE" /var/log/audit/audit.log | tail -n 1)            
            IFS=$'\n'  # Set the Internal Field Separator to newline
            for log in $logs; do
                #  echo "$log"
                echo " "
                eventID=$(echo "$log" | grep -oE 'audit\([0-9.]+:([0-9]+)' | awk -F: '{print $2}')
                syscallLog=$(grep -E "type=SYSCALL.*:$eventID\)" /var/log/audit/audit.log)
                #echo "$syscallLog"
                epochTime=$(echo "$log" | grep -oE 'audit\([0-9]*\.[0-9]*' | awk -F"(" '{print $2}')
                lastModifiedTime=$(TZ="Asia/Kolkata" date -d "@$epochTime" "+%Y-%m-%d %H:%M:%S")
                success=$(echo "$syscallLog" | grep -o 'success=[^ ]*' | awk -F'=' '{print $2}')
                command=$(echo "$syscallLog" | grep -o 'comm="[^"]*"' | sed 's/comm="//;s/"//')
                keyWord=$(echo "$syscallLog" | grep -o 'key="[^"]*"' | sed 's/key="//;s/"//')
                action=$(echo "$syscallLog" | grep -o 'SYSCALL=[^ ]*' | awk -F'=' '{print $2}')
                auid=$(echo "$syscallLog" | grep -o 'AUID="[^"]*"' | sed 's/AUID="//;s/"//')

                logMes="LastModifiedTime=$lastModifiedTime, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action=$eventAction, FileDir=$dir, Hash=$newHash, Success=$success, Command=$command, Key=$keyWord, Action=$action, AUID=$auid"
                echo "$logMes"
                echo "$logMes" >> /var/log/fim.log
            done
            unset IFS
            unset "fileForHash[$key]"
        fi        
    done 

    for file in $FILELIST; do
        if [[ -v fileForHash["/root/TMK/secFolder/$file"] ]]; then
            echo "/root/TMK/secFolder/$file exists in the array."
        else
            echo "/root/TMK/secFolder/$file does not exist in the array. It sould be added to the array"

            hashFilePair=$(md5sum /root/TMK/secFolder/$file)
            #echo "$hashFilePair"
            read newHash key <<< "$hashFilePair"
            fileForHash[$key]=$newHash
            shouldUpdate=true

            ## logger command ##
            eventAction="CREATED"
            miniLogCreator
            detailedLogCreator

        fi
    done

    if [ "$shouldUpdate" = true ]; then
        updateCurrentFile
    fi
}
###########################################
appendToDeletedList(){
    output_file="/root/TMK/imp/deletedFiles.txt"
    # Loop through the array and write its contents to the file
    echo "File: $key, \tHash: ${deletedFiles[$key]}" >> "$output_file"
}
###########################################
updateCurrentFile(){
    # Loop through the array and write its contents to the file
    currentfile="/root/TMK/imp/currentFiles.txt"
    cat /dev/null > "$currentfile"
    for key in "${!fileForHash[@]}"; do
        echo -e "File: $key, \tHash: ${fileForHash[$key]}" >> "$currentfile"
    done
}

#### $eventAction sholud define before use this function
miniLogCreator(){
    #### $eventAction $key $newHash sholud define before use this function
    EVENTSOURCE_IP=`hostname -I | awk '{print $1}'`
    distro=`cat /etc/os-release | grep -oP 'PRETTY_NAME="\K[^"]+'`
    IP=`who am i |awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip'}`
    dir=$key
    lastModifiedTime=$(stat -c "%y" $key)

    logMes="LastModifiedTime=$lastModifiedTime, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action=$eventAction, FileDir=$dir, Hash=$newHash"
    echo "$logMes"
    echo "$logMes" >> /var/log/fim.log
}

detailedLogCreator(){
    #### $eventAction sholud define before use this function
    lastModifiedTime=$(stat -c "%y" $key)
    time="$lastModifiedTime"
    stime=$(date -d "$time" "+%s")
    ms=$(echo $time | awk '{sub(/.*\./,""); print substr($1, 1, 3)}')
    mstime=$(echo "$stime.$ms")

    FileDir="$dir"
    file=$(basename $FileDir)
    filesrch="$file\""
    logs=$(grep "$mstime.*$filesrch.*nametype=CREATE" /var/log/audit/audit.log)

    if [ -z "$logs" ]; then
        echo "The variable is empty."
        logs=$(grep "$filesrch.*nametype=CREATE" /var/log/audit/audit.log | tail -n 1)
    fi


    IFS=$'\n'  # Set the Internal Field Separator to newline
    for log in $logs; do
        #  echo "$log"
        echo " "
        eventID=$(echo "$log" | grep -oE 'audit\([0-9.]+:([0-9]+)' | awk -F: '{print $2}')
        syscallLog=$(grep -E "type=SYSCALL.*:$eventID\)" /var/log/audit/audit.log)
        #echo "$syscallLog"

        success=$(echo "$syscallLog" | grep -o 'success=[^ ]*' | awk -F'=' '{print $2}')
        echo "Success status is : $success"
        command=$(echo "$syscallLog" | grep -o 'comm="[^"]*"' | sed 's/comm="//;s/"//')
        keyWord=$(echo "$syscallLog" | grep -o 'key="[^"]*"' | sed 's/key="//;s/"//')
        action=$(echo "$syscallLog" | grep -o 'SYSCALL=[^ ]*' | awk -F'=' '{print $2}')
        auid=$(echo "$syscallLog" | grep -o 'AUID="[^"]*"' | sed 's/AUID="//;s/"//')

        logMes="LastModifiedTime=$lastModifiedTime, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, EventType="FS", Event_Action=$eventAction, FileDir=$dir, Hash=$newHash, Success=$success, Command=$command, Key=$keyWord, Action=$action, AUID=$auid"
        echo "$logMes"
        # echo "$logMes" >> /var/log/fim.log
    done
    echo "end of the for loop"
    unset IFS
}
############################################
############################################
############################################
declare -A fileForHash
declare -A deletedFiles

# Specify the input file
input_file="/root/TMK/imp/currentFiles.txt"

# Check if the input file exists
if [ -f "$input_file" ]; then
    # Read the input file line by line
    while IFS= read -r line; do
        # Split the line into key and value
        key=$(echo "$line" | awk -F 'File: ' '{print $2}' | awk -F ',' '{print $1}')
        value=$(echo "$line" | awk -F 'Hash: ' '{print $2}')
        # echo "$key ---> $value"
        fileForHash[$key]=$value
    done < "$input_file"

    # Display the imported array
    for key in "${!fileForHash[@]}"; do
        echo "Key: $key, Value: ${fileForHash[$key]}"
    done
else
    echo "Input file '$input_file' not found."
    FileListUpdate 
    `touch /root/TMK/imp/currentFiles.txt`
    updateCurrentFile
fi

i=0
while [ $i -lt 10 ]; do
    FileListCheck

    for key in "${!fileForHash[@]}"; do
        shouldUpdate=false
        oldHash="${fileForHash[$key]}"
        read newHash p <<< $(md5sum $key)
       # echo "old hash is $oldHash    ---->    new hash is $newHash"
        #echo "olhHash: $oldHash, newHash: $newHash"

        if [ "$oldHash" != "$newHash" ]; then
            shouldUpdate=true
            echo "The file $key was changed."
            fileForHash[$key]=$newHash

            ## logger command ##
            eventAction="MODIFIED"
            miniLogCreator
            detailedLogCreator

            if [ "$shouldUpdate" = true ]; then
                updateCurrentFile
            fi     
        fi
    done
    sleep 10
done


