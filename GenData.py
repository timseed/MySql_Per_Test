#!/bin/python
#ID,NAME,Address,Phone,Custtype


import sys
items=int(sys.argv[1])
for n in range (1,items):
   print ("%d,NAME%d,Adress Street %d,44123%d,%d"%(n,n,n,n,n%4))

