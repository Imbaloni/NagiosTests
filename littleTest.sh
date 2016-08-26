WARNING=0.00000000089
CRITICAL=0.01
lsqaVar="diesisteintollerstring 0.0001"
substring=${lsqaVar:22}
echo $substring
echo $(echo "$substring >= $WARNING" |bc -l)
echo $(echo "$substring < $CRITICAL" |bc -l)
if (( $(echo "$substring >= $WARNING" |bc -l 2>/dev/null) )) &&  (( $(echo "$substring < $CRITICAL" |bc -l 2>/dev/null) )); then
    EXIT_CODE=$STATE_OK
    echo "alles gut"
else
    echo "nix gut"
fi