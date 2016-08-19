#check if a database nagiosdatabase exists, which was created by nagios user
START=$(date +0%s.%3N)
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
INIT=false
TABLENAME=nagiosTable
if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]]; then
    echo "This script checks if a database with the name nagiosDatabase exists and does a query to the table nagiosTable."
    echo "If the nagioTable does not exist or is not the default MySQL table please create it or make it default."
    echo ""
    echo "Must exist:"
    echo "-u|--user mysql username"
    echo "-p|--pass mysql password (is not safe)"
    echo "-d|--database specify the database to be used"
    echo "-w|--warning lower bound of the warning range"
    echo "-c|--critical upper bound of the critical range"
    echo ""
    echo "Optional: "
    echo "-i|--init if set true a new table can be created"
    echo "-t|--tablename specify the name of the table to be created"
    echo "Example:"
    echo "./check_mysql_Timo -u nagios -p nagios-pass -d nagiosDatabase -w 0 -c 1"
    echo "this will do a simple query on the table nagiosTable(default) to see if it responds"
    echo "./check_mysql_Timo -u nagios -p nagios-pass -d nagiosDatabase -w 0 -c 1 -i true -t newTablename"
    echo "creates a new table with newTablename and does a query(default) on it."
    echo "Warning: if neither the database or the table responds in time."
    echo "Critical: if the database does not exists."
    exit 0;
fi
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
        -d|--database)
            shift&&DATABASE="$1"||die
            ;;
        -w|--warning)
            shift&&WARNING="$1"||die
            ;;
        -c|--critical)
            shift&&CRITCAL="$1"||die
            ;;
        -t|--tablename)
            shift&&TABLENAME="$1"||die
            ;;
        -i|--init)
            shift&&INIT="$1"||die
            ;;
   esac
   shift
done
echo USER = "$USER"
echo PASS = "$PASS"
echo DATABASE = "$DATABASE"
echo WARNING = "$WARNING"
echo CRITCAL = "$CRITCAL"
echo TABLENAME = "$TABLENAME"
echo INIT = "$INIT"
#tries to connect to the database and safes the mysql output of all databases in a string
RESULT=$(mysqlshow --user=$USER --password\=$PASS)
if [[ $RESULT != *"$DATABASE"* ]]; then
    STATE_TEXT="CRITICAL: Database "$DATABASE" does not respond. Check wheather mysql is running or if the database nagiosDatabase exists."
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT
    exit $EXIT_CODE;
fi
#if init is true, the own table will be created with the -t argument, else is standard and nagiosTable will be used
if [ "$INIT" = true ]; then
    echo CREATING TABLE "$TABLENAME"
    (mysql -D $DATABASE --user $USER --password\=$PASS -se "create table if not exists "$TABLENAME" (id int primary key, date tinytext); ") 
else
    echo CREATING TABLE "$TABLENAME"
    (mysql -D $DATABASE --user $USER --password\=$PASS -se "create table if not exists "$TABLENAME" (id int primary key, date tinytext); ") 
fi

#fill table with the current time as string and waits for one second
CURRENTDATE=$(date +%D-%T)
if ! (mysql -D $DATABASE --user $USER --password\=$PASS -se "INSERT INTO "$TABLENAME" VALUES (1,'"$CURRENTDATE"')ON DUPLICATE KEY UPDATE date='"$CURRENTDATE"';") > /dev/null 2>&1; then
    STATE_TEXT="CRITICAL: Couldn't insert into "$TABLENAME" database gone?"
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT
    exit $EXIT_CODE;
else   
    EXIT_CODE=$STATE_OK
fi
sleep 1
#checks if the currenttime is identical to the time in the table
if ! (mysql -D $DATABASE --user $USER --password\=$PASS -se "select date from "$TABLENAME" where id=1 and date='"$CURRENTDATE"';") > /dev/null 2>&1 ;then 
    STATE_TEXT="CRITICAL: Couldn't select date="$CURRENTDATE" from "$TABLENAME" : date given was "$CURRENTDATE" , compare date with table!"
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT
    exit $EXIT_CODE;
else
    EXIT_CODE=$STATE_OK
fi

#if database is up and running the table will be checked
if  ! mysql -D $DATABASE --user $USER --password\=$PASS -se "select * from "$TABLENAME"; " > /dev/null 2>&1 ; then
        STATE_TEXT="WARNING: nothing to select from table: "$TABLENAME" .Table dropped?"
        EXIT_CODE=$STATE_WARNING
fi
#if the result didn't fetch anything in time or is empty a critical message will be fired
STOP1=$(date +0%s.%3N);
DURATION=$(echo "((($STOP1-1) - $START))" | bc)
if (( $(echo "$DURATION > $CRITCAL" |bc -l 2>/dev/null) )); then
    STATE_TEXT="CRITICAL: Database "$DATABASE" does not respond. Check wheather mysql is running or if the database nagiosDatabase exists."
    EXIT_CODE=$STATE_CRITICAL
    echo $STATE_TEXT
    exit $EXIT_CODE;
fi
#if response is in between warning and critical, everything is fine!
if (( $(echo "$DURATION > $WARNING" |bc -l 2>/dev/null) )) && (( $(echo "$DURATION < $CRITCAL" |bc -l) )); then
    EXIT_CODE=$STATE_OK
#if response is not in between but less then critical a warning is displayed
else 
    STATE_TEXT="WARNING: Table/Database not responded in given time bounds. Mysql slow?"
    EXIT_CODE=$STATE_WARNING
    echo $STATE_TEXT 
fi

#Different messages will be fired either the exit code was OK, WARNING or CRITICAL
if [[ $EXIT_CODE -eq 0 ]]; then
    STATE_TEXT="OK: Database and Table found in time"
    echo $STATE_TEXT
fi
if [[ $EXIT_CODE -eq 1 ]]; then
    echo $STATE_TEXT
fi

#the duration of the script will be printed
printf "Duration was: %.3f\n" $DURATION
exit $EXIT_CODE;