# Testing the variables of the galera clusters below
# wsrep_local_send_queue_avg, wsrep_local_recv_queue_avg, wsrep_local_state_comment, wsrep_cluster_size, wsrep_connected and wsrep_ready

START=$(date +0%s.%3N)
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

if [[ -z "$1" ]];then 
    echo "Use --help or -h for more options."
    exit 1;
fi

while (( "$#" )); do
   case $1 in
        -u|--user)
            shift&&USER="$1"||die
            ;;
        -p|--pass)
            shift&&PASS="$1"||die
            ;;
        -v1|--variable1)
            shift&&VARIABLE1="$1"||die
            ;;
        -v2|--variable2)
            shift&&VARIABLE2="$1"||die
            ;;
   esac
   shift
done
echo USER = "$USER"
echo PASS = "$PASS"
echo VARIABLE1 = "$VARIABLE1"
echo VARIABLE2 = "$VARIABLE2"
query1=$(mysql -D DBTest --user $USER --password\=$PASS -s -N -e "show status like 'compression';")
substring1=${query1:12}
if [[ $substring1 != "$VARIABLE1" ]]; then
    echo "we butter the bread with butter!"
else
    echo "everything is fine"
fi

query2=$(mysql -D DBTest --user $USER --password\=$PASS -s -N -e "show status like 'Handler_rollback';")
substring2=${query2:17}
if [[ $substring2 != "$VARIABLE1" ]]; then
    echo "variable not in range"
else
    echo "variable in range"
fi
echo $substring1
echo $substring2