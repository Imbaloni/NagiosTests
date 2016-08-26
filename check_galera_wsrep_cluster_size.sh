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
    echo "This script checks wsrep_cluster_size with a critical state"
    echo "How to use: "
    echo "./check_galera_wsrep_cluster_size.sh -u USER -p PASS -c"
    echo "Whereas there is a critcal if the cluster size is not the -c parameter"
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
   esac
   shift
done
echo USER = "$USER"
echo PASS = "$PASS"
echo CRITICAL = "$CRITICAL"
query=$(mysql --user $USER --password\=$PASS -s -N -e "show status like 'wsrep_cluster_size';")
csVar=${query:18}
echo $lrqaVar
if [[ "$csVar" -eq "$CRITICAL" ]]; then
    EXIT_CODE=$STATE_OK
else
    STATE_TEXT="CRITICAL: Found "$csVar". Given "$CRITICAL"."
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT 
fi


exit $EXIT_CODE;
