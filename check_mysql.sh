#check if a database nagiosdatabase exists, which was created by nagios user

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

RESULT=`mysqlshow --user=nagios --password=nagios-pass "nagiosDatabase" 2>/dev/null `

if [[ $RESULT == *"nagiosDatabase"* ]]; then
    STATE_TEXT="Ok: Database exists"
    EXIT_CODE=$STATE_OK
else 
    STATE_TEXT="Critical: Database was not found"
    EXIT_CODE=$STATE_CRITICAL
fi

echo $STATE_TEXT
exit $EXIT_CODE;