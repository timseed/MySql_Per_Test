# MySql_Per_Test
MySQL Performance tests using Python and mysqlimport


#MySQL 

I need to investigate speeding up a Mysql Database for the office. So this is how will setup and test.


* Install and Test Mysql
* Create Tables
* Create Data sets to load
* Develop similar load 
* Record the timings

Next

Try and Improve things using

* Indexes
* Transactions
* Something else ????....

Sounds like a plan .... Let's go

# Install
As I am doing this on Ubuntu 14

So 

```bash
    apt-get install mysqld
```

Then put my Db commands into 1_Create.sql

```sql
drop database pt;

Create database pt;
use pt;

create table customers ( ID INT, NAME varchar(20), Address Varchar(80), Phone Va
rchar(30), Custtype int );

create table customers_update ( ID INT, NAME varchar(20), Address Varchar(80), P
hone Varchar(30), Custtype int );

create unique index customers_U_id on customers (ID);
create index customers_name  on customers (NAME);
create index customers_custtype on customers (Custtype);

```

Now create the Db - like this 

    mysql <1_Create_db.sql
    
As I am on private machine I am not using username and password !!! **Do not do this on an internet connected machine**

Db Created.

#Load Table

I am lazy - so as I need several 000's of records - I am going to write a small data generator.

```python
#!/bin/python
#ID,NAME,Address,Phone,Custtype


import sys
items=int(sys.argv[1])
for n in range (1,items):
   print ("%d,NAME%d,Adress Street %d,44123%d,%d"%(n,n,n,n,n%4))
```
   
Test it like this

    python Gen_Data.py 5
    
And I see

```text
1,NAME1,Adress Street 1,441231,1
2,NAME2,Adress Street 2,441232,2
3,NAME3,Adress Street 3,441233,3
4,NAME4,Adress Street 4,441234,0
```

Which is what I want - to put it in a file just do

  python Gen_Data.py 5 > customers.csv
  
**Note the file name is important**

# Load the Customers Table

Using mysqlimport 

    mysqlimport pt customers.csv -L --fields-terminated-by=','
    
A quick **select * from customers;** gives

```sql
+------+-------+-----------------+--------+----------+
| ID   | NAME  | Address         | Phone  | Custtype |
+------+-------+-----------------+--------+----------+
|    1 | NAME1 | Adress Street 1 | 441231 |        1 |
|    2 | NAME2 | Adress Street 2 | 441232 |        2 |
|    3 | NAME3 | Adress Street 3 | 441233 |        3 |
|    4 | NAME4 | Adress Street 4 | 441234 |        0 |
+------+-------+-----------------+--------+----------+

```

To Load data into customers_update

    cp customers.csv customers_update.csv
    mysqlimport pt customers_update.csv -L --fields-terminated-by=','
    
#Update 

I am going to use a Transaction to do the update.

I have placed these commands in a .sql file called 2_update.sql 

And I will run it using 

    mysql pt < 2_update.sql
    

```mysql
start transaction;
select now(),'delete starting' from dual;
delete from customers where custtype=2;
select now(),'Insert Starting ' from dual;
insert into customers (select * from customers_update where custtype =2);
select now(),'Commit Starting ' from dual;
commit;
select now(),'Commit Done' from dual;

```

When I run this I get

```text
now()	delete starting
2015-06-15 11:24:19	delete starting
now()	Insert Starting 
2015-06-15 11:24:49	Insert Starting 
now()	Commit Starting 
2015-06-15 11:25:41	Commit Starting 
now()	Commit Done
2015-06-15 11:25:41	Commit Done

```


|operation |  time|
|:------------|--------:|
|  Delete    |  30s   |
|  Insert    |  52s   |
|  Commit    |   0s   |
 
 
As the data should be evenly split - this is 250,000 records. Which I think is quite acceptable.
  
  
## What happens to the user query time when this is happening ?

I will not create a random Query (to stope the Db Caching) - and run this as the previous update is running. 

First the query code....

```python
import mysql.connector
import random
import sys
from timeit import Timer
import datetime

#
#Query use a Primary Key
#
def Query(num):
	global cnx
	cursor = cnx.cursor()
	query = "SELECT ID,NAME,Custtype from customers WHERE ID = {0}"
	cursor.execute(query.format(num))
	for (cid, name, ctype ) in cursor:
		print("{}, {} {} ".format(
    		cid, name, ctype ))
	cursor.close()
	
#
# Main Loop
#

loop=1+int(sys.argv[1])
#
#mysql Connect 1 time only
#
start=datetime.datetime.now()
cnx = mysql.connector.connect(user='root',database='pt')

for q in range(1,loop):
	num=random.randrange(1,1000000)
	Query(num)
	#
  	#Timeit using lambda 
	#
	#t = Timer(lambda: Query(num))
	#print ("\t\t\t\t{0}".format(t.timeit(number=1)))
cnx.close()
end=datetime.datetime.now()
print("Query for %d took %d seconds"%(loop,(end-start).seconds))



```  


You run this like....

    time python Query.py 5000 
    
You will see .... 

```text
469518, NAME469518 2 
975783, NAME975783 3 
Query for 5001 took 2 seconds

```
On my hardware/setup the average time for 5000 queries is 2 seconds. 

```
Query for 5001 took 2.883825 seconds
Query for 5001 took 2.870572 seconds
Query for 5001 took 2.958822 seconds
Query for 5001 took 2.929722 seconds
Query for 5001 took 2.755262 seconds
Query for 5001 took 2.822934 seconds
Query for 5001 took 2.905826 seconds
Query for 5001 took 2.895257 seconds
Query for 5001 took 2.846605 seconds
Query for 5001 took 2.894246 seconds
```



## Time with Update running

We need t execute two tasks at the same time - so we will use some Linux command line foo

```bash
    rm *.log
    nohup mysql pt < 2_update.sql 2>1 >> update.log&
    sleep 4s
    for a in $(seq 10);do python Query.py 5000 | grep Query; done

```    

I placing the sleep - to make sure that the Transaction is in place.

The worst sample I found was

```text
Query for 5001 took 2.435922 seconds
Query for 5001 took 4.502661 seconds
Query for 5001 took 3.130135 seconds
Query for 5001 took 3.333874 seconds
Query for 5001 took 2.069113 seconds
Query for 5001 took 2.094691 seconds
Query for 5001 took 2.140467 seconds
Query for 5001 took 2.011877 seconds
Query for 5001 took 2.145676 seconds
Query for 5001 took 2.175512 seconds
```

Which shows a slight jitter from 2.4-4.5 seconds  - but is still reasonable.

Which I found surprising....

I will increase the datasize to 10M records and try and break it again.

#10 Million Records

## Update No Query RUnning


 command     | time     |  Increase  |
:-------------|:----------:|------------:|
 Delete      |   900s   | 30 times   |
 Insert      |   430s   |  8 times   |
 Commit      |    0     |  0 times |
 
 10M Instead of 1M - so you would expect 10-15 times slower. Delete seems Slow - but Insert seems in line.
 
 
#Partition

After some digging around in the system and some reading - I wondered if the solution we would use with an Oracle Db would also work - partition the table.

With a loaded Table I did the following sql command.

    ALTER TABLE customers 
    PARTITION BY HASH(ID)
    PARTITIONS 4;

I then ran the **update** script again. These were the figures I got.

 command     | time     |  Increase  |
:-------------|:----------:|------------:|
 Delete      |   360s   | 11 times   |
 Insert      |   270s   |  5 times   |
 Commit      |    0     |  0 times|
 
