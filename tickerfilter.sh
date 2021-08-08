#!/bin/bash
clean_up() {
    steampipe service stop --force
}
trap clean_up EXIT

today=$(date +"%Y-%m-%d")

cd Buy_Call
symbols=()
echo 'symbol,short_name,change,regular_market_price,fifty_two_week_high,fifty_two_week_low,fifty_day_average,two_hundred_day_average,regular_market_open,regular_market_day_high,regular_market_day_low,regular_market_previous_close,regular_market_volume' >Buy_Call_${today}.csv
{
    # this reads the first row which has the column names so we will not go
    # through that row in the loop below
    read
    while IFS="," read -r -a arr; 
    do
        symbols+=(${arr[@]:0:1}.NS)
    done
} <../NSE_Symbols.csv

for sym in "${symbols[@]}"
do
    { # try

        steampipe query "select symbol,short_name,(fifty_two_week_high-regular_market_price)*100/fifty_two_week_high as change,
        regular_market_price,fifty_two_week_high,fifty_two_week_low,fifty_day_average,two_hundred_day_average,
        regular_market_open,regular_market_day_high,regular_market_day_low,regular_market_previous_close,
        regular_market_volume from finance.finance_quote 
        where symbol = '${sym}' and (fifty_day_average < two_hundred_day_average) 
        order by regular_market_price desc" --header=false --output csv >> Buy_Call_${today}.csv

    } || { # catch
        echo "fetch call failed for " ${sym}
    }
done
