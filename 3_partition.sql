ALTER TABLE customers 
    PARTITION BY HASH(ID)
    PARTITIONS 4;