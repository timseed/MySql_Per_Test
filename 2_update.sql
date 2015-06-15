start transaction;
select now(),'delete starting' from dual;
delete from customers where custtype=2;
select now(),'Insert Starting ' from dual;
insert into customers (select * from customers_update where custtype =2);
select now(),'Commit Starting ' from dual;
commit;
select now(),'Commit Done' from dual;
