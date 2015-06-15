drop database pt;


Create database pt;
use pt;

create table customers ( ID INT, NAME varchar(20), Address Varchar(80), Phone Varchar(30), Custtype int );

create table customers_update ( ID INT, NAME varchar(20), Address Varchar(80), Phone Varchar(30), Custtype int );

create unique index customers_U_id on customers (ID);
create index customers_name  on customers (NAME);
create index customers_custtype on customers (CUSTTYPE);



show tables;
