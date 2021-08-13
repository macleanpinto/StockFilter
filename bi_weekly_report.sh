#!/bin/bash
clean_up() {
    steampipe service stop --force
}
trap clean_up EXIT

date=$(date -j -v-14d +"%Y-%m-%d")
today=$(date +"%Y-%m-%d")

cd Bi_Weekly_Report
echo 'symbol,short_name,previous_market_price,regular_market_price,change,price_two_weeks_back,fifty_two_week_high,fifty_two_week_low,fifty_day_average,two_hundred_day_average,regular_market_open,regular_market_day_high,regular_market_day_low,regular_market_previous_close,regular_market_volume' >Bi_Weekly_Report_${today}.csv

{
    # this reads the first row which has the column names so we will not go
    # through that row in the loop below
    read
    while IFS=, read -a arr 
    do
        if [ "${arr}" != "" ]; then
            steampipe query "select symbol,short_name,${arr[@]:2:1} as previous_market_price,regular_market_price,
            (regular_market_price-${arr[@]:2:1})*100/${arr[@]:2:1} as change,fifty_two_week_high,fifty_two_week_low,fifty_day_average,two_hundred_day_average,
            regular_market_open,regular_market_day_high,regular_market_day_low,regular_market_previous_close,
            regular_market_volume from finance.finance_quote 
            where symbol = '${arr[@]:0:1}' and regular_market_price > ${arr[@]:2:1}
            order by regular_market_price desc" --header=false --output csv < /dev/null >> Bi_Weekly_Report_${today}.csv;
        fi
    done
} < ../Buy_Call/Buy_Call_${date}.csv
