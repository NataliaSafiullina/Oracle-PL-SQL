set serveroutput on; 

explain plan for
    SELECT count(*),   
       round(avg(quantity_on_hand)) AVG_AMT, 
       product_id, product_name 
    FROM inventories natural join product_information 
    GROUP BY product_id, product_name;
set echo off
--- Display the execution plan. Verify that the query result 
--- is placed in the Result Cache.
@$ORACLE_HOME/rdbms/admin/utlxpls 

explain plan for
    SELECT /*+ result_cache */ 
       count(*),   
       round(avg(quantity_on_hand)) AVG_AMT, 
       product_id, product_name 
    FROM inventories natural join product_information 
    GROUP BY product_id, product_name;
set echo off
@$ORACLE_HOME/rdbms/admin/utlxpls

/*
Следующий код используется для выборки имен из таблицы WAREHOUSES.
Таблица WAREHOUSES изменяется достаточно редко.
Измените функцию таким образом, чтобы результаты ее выполнения попадали в кэш.
*/

CREATE OR REPLACE TYPE list_typ IS TABLE OF VARCHAR2(35);

CREATE OR REPLACE FUNCTION get_warehouse_names 
RETURN list_typ 
RESULT_CACHE RELIES_ON (warehouses)
IS
  v_count BINARY_INTEGER;
  v_wh_names list_typ := list_typ();
BEGIN
  SELECT count(*) 
    INTO v_count 
    FROM warehouses;
  v_wh_names.extend(v_count);
  FOR i in 1..v_count LOOP
    SELECT warehouse_name 
    INTO v_wh_names(i)
    FROM warehouses
    where warehouse_id = i;
  END LOOP;
  RETURN v_wh_names;
END get_warehouse_names;  

