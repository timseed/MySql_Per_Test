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
	num=random.randrange(1,10000000)
	Query(num)
	#
  	#Timeit using lambda 
	#
	#t = Timer(lambda: Query(num))
	#print ("\t\t\t\t{0}".format(t.timeit(number=1)))
cnx.close()
end=datetime.datetime.now()
print("Query for %d took %f seconds"%(loop,float((end-start).total_seconds())))

