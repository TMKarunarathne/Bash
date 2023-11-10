distro=`cat /etc/os-release | grep -oP 'PRETTY_NAME="\K[^"]+'`
function history_to_syslog
{
EVENTSOURCE_IP=`hostname -I | awk '{print $1}'`
IP=`who am i |awk '{match($0,/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/); ip = substr($0,RSTART,RLENGTH); print ip'}`
CMD=$(history 1)
CMD=$(echo $CMD |awk '{print substr($0,length($1)+2)}')
CMD_FILE=$(echo $CMD | grep -aoh -e "rm".* -aoh -e "mkdir".* -aoh -e "touch".* -aoh -e "mv".* -aoh -e "tee".* -aoh -e "vi".* -aoh -e "nano".* -aoh -e "vi    m".*)
DIR=$(pwd)
USER=$(echo $USER)
if [ "$CMD" != "$OLD_CMD" ]; then
    logger -p local6.debug -- SESSIONHISTORY=$$, USER=$USER, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, PWD=$DIR, CMD="${CMD}", IP=${IP}
fi
if [[ ! $CMD_FILE == "" ]]
    then
    if [[ $CMD_FILE == *"rm"* || $CMD_FILE == *"mv"* ]]
        then
        $(echo $CMD_FILE | cut -d\   -f2)
        logger -p local6.debug -- SESSIONHISTORY=$$, USER=$USER, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, PWD=$DIR, CMD="${CMD}", IP=${IP}, EventType="FS", Eve    nt_Action="DELETE", FileDir=$dir
    fi
    if [[ $CMD_FILE == *"mkdir"* || $CMD_FILE == *"touch"* || $CMD_FILE == *"nano"* || $CMD_FILE == *"vi"* || $CMD_FILE == *"vim"* || $CMD_FILE == *"tee"* ]]
        then
        dir=$(echo $CMD_FILE | cut -d\   -f2)
        logger -p local6.debug -- SESSIONHISTORY=$$, USER=$USER, OS=$distro, EVENTSOURCEIP=$EVENTSOURCE_IP, PWD=$DIR, CMD="${CMD}", IP=${IP}, EventType="FS", Eve    nt_Action="WRITE", FileDir=$dir
    fi
fi
OLD_CMD=$CMD
}
trap history_to_syslog DEBUG || EXIT

#this is comment
