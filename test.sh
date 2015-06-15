#!/bin/bash

function h {
echo "============================================="
echo $1
echo " "
}
function f {
echo "============================================="
}

h CreateDb
time mysql < 1_Create_db.sql
f

h CreateData
time python GenData.py 10000000  > customers.csv
f

h LoadData
mysqlimport pt customers.csv -L --fields-terminated-by=','
f


cp customers.csv customers_update.csv
h Load_Customer_Update
mysqlimport pt customers_update.csv -L --fields-terminated-by=','
f

