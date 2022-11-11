-- task 4
/*
Создайте таблицу для хранения информации о кредитных картах
*/
-- создаём объект с двумя полями
CREATE TYPE typ_cr_card AS OBJECT
(card_type VARCHAR2(25), card_num NUMBER);
-- создаём таблицу, где записи типа объекта выше
CREATE TYPE typ_cr_card_nst AS TABLE OF typ_cr_card;
-- создаём столбец в таблице, где будет вложенная таблица
ALTER TABLE customers ADD
    (credit_cards typ_cr_card_nst)
    NESTED TABLE credit_cards STORE AS c_c_store_tab;

-- task 5
/*
Создайте PL/SQL пакет для управления значениями в столбце credit_cards column таблицы CUSTOMERS.
*/
CREATE OR REPLACE PACKAGE credit_card_pkg
IS
  PROCEDURE update_card_info
    (p_cust_id NUMBER, p_card_type VARCHAR2, p_card_no VARCHAR2);
    
  PROCEDURE display_card_info
    (p_cust_id NUMBER);
END credit_card_pkg;  -- package spec

CREATE OR REPLACE PACKAGE BODY credit_card_pkg
IS

  PROCEDURE update_card_info (p_cust_id NUMBER, p_card_type VARCHAR2, p_card_no VARCHAR2)
  IS
    v_card_info typ_cr_card_nst;
    i INTEGER;
  BEGIN
    SELECT credit_cards
      INTO v_card_info
      FROM customers
      WHERE customer_id = p_cust_id;
    IF v_card_info.EXISTS(1)
    THEN  
    -- cards exist, add   
    -- fill in code here
        i := v_card_info.LAST;
        v_card_info.EXTEND(1);
        v_card_info(i+1) := typ_cr_card(p_card_type, p_card_no);
        UPDATE customers
            SET credit_cards = v_card_info
            WHERE customer_id = p_cust_id;
            
     ELSE
    -- no cards for this customer, construct one
    -- fill in code here
        UPDATE customers
            SET credit_cards = typ_cr_card_nst
                (typ_cr_card(p_card_type, p_card_no))
            WHERE customer_id = p_cust_id;
        
    END IF;
  END update_card_info;


  PROCEDURE display_card_info (p_cust_id NUMBER)
  IS
    v_card_info typ_cr_card_nst;
    i INTEGER;
  BEGIN
    SELECT credit_cards
      INTO v_card_info
      FROM customers
      WHERE customer_id = p_cust_id;

    -- fill in code here to display the nested table
    -- contents
    IF v_card_info.EXISTS(1)
        THEN
            FOR idx IN v_card_info.FIRST..v_card_info.LAST LOOP
             DBMS_OUTPUT.PUT('Card Type: ' || v_card_info(idx).card_type || ' ');
             DBMS_OUTPUT.PUT_LINE('/ Card No: ' || v_card_info(idx).card_num );
            END LOOP;
        else
            DBMS_OUTPUT.PUT_LINE('Customer has no credit cards.');
    END IF;

  END display_card_info;  
END credit_card_pkg;  -- package body
-- тестирование
SET SERVEROUTPUT ON
EXECUTE credit_card_pkg.display_card_info(120);
EXECUTE credit_card_pkg.update_card_info(120, 'Visa', 11111111);

SELECT credit_cards 
FROM   customers 
WHERE  customer_id = 120;

EXECUTE credit_card_pkg.update_card_info(120, 'MC', 2323232323);
EXECUTE credit_card_pkg.update_card_info(120, 'DC', 4444444);

--task 7
/*
Для sqlplus код решения:

SELECT c.CUSTOMER_ID, c.CUST_LAST_NAME, cc.CARD_TYPE, cc.CARD_NUM
FROM   customers c, TABLE(c.credit_cards) cc
WHERE  customer_id = 120
/

*/
