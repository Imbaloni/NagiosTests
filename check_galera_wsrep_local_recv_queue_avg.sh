# Testing the variables of the galera clusters below
# wsrep_local_send_queue_avg, wsrep_local_recv_queue_avg, wsrep_local_state_comment, wsrep_cluster_size, wsrep_connected and wsrep_ready
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

if [[ -z "$1" ]];then 
    echo "Use --help or -h for more options."
    exit 1;
fi
if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]]; then
    echo "This script checks wsrep_local_recv_queue_avg with a warning and critical state"
    echo "How to use: "
    echo "./check_galera_wsrep_local_recv_queue_avg.sh -u USER -p PASS -w -c"
    echo "Whereas the warning and critical is in seconds (average is 0.010564)"
fi
while (( "$#" )); do
   case $1 in
        -u|--user)
            shift&&USER="$1"||die
            ;;
        -p|--pass)
            shift&&PASS="$1"||die
            ;;
        -c| --critical)
            shift&&CRITICAL="$1"||die
            ;;
        -w| --warning)
            shift&&WARNING="$1"||die
            ;;
   esac
   shift
done
echo USER = "$USER"
echo PASS = "$PASS"
echo WARNING = "$WARNING"
echo CRITICAL = "$CRITICAL"
query=$(mysql --user $USER --password\=$PASS -s -N -e "show status like 'wsrep_local_recv_queue_avg';")
lrqaVar=${query:26}
echo $lrqaVar
if (( $(echo "$lrqaVar >= $WARNING" |bc -l 2>/dev/null) )) &&  (( $(echo "$lrqaVar < $CRITICAL" |bc -l 2>/dev/null) )); then
    EXIT_CODE=$STATE_OK
else
    STATE_TEXT="WARNING: Found time "$lrqaVar" was not in warning and critcal area"
    EXIT_CODE=$STATE_WARNING
    echo $STATE_TEXT 
fi

if (( $(echo "$lrqaVar >= $CRITCAL" |bc -l 2>/dev/null) )); then
    STATE_TEXT="CRITICAL: Found time "$lrqaVar" was beyond critcal area"
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT
fi

exit $EXIT_CODE;
