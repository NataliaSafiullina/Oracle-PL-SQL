select count(*) from orders;

SET SERVEROUTPUT ON
--// task 1
BEGIN
	UPDATE orders SET order_status = order_status;
	FOR v_rec IN ( SELECT order_id FROM orders )
	LOOP
		IF sql%ISOPEN THEN
		   DBMS_OUTPUT.PUT_LINE('TRUE Ц ' || SQL%ROWCOUNT);
		ELSE
		   DBMS_OUTPUT.PUT_LINE('FALSE Ц ' || SQL%ROWCOUNT);
		END IF;
	END LOOP;
END;

BEGIN
	UPDATE orders SET order_status = order_status;
	FOR v_rec IN ( SELECT order_id FROM orders )
	LOOP
		IF v_rec%ISOPEN THEN
		   DBMS_OUTPUT.PUT_LINE('TRUE Ц ' || v_rec%ROWCOUNT);
		ELSE
		   DBMS_OUTPUT.PUT_LINE('FALSE Ц ' || v_rec%ROWCOUNT);
		END IF;
	END LOOP;
END;

--//task 2
DECLARE
	CURSOR cur_update 
    IS SELECT * FROM customers 
    WHERE credit_limit < 5000 FOR UPDATE;
BEGIN
	FOR v_rec IN cur_update
	LOOP
			UPDATE customers 
			SET credit_limit = credit_limit + 200
			WHERE customer_id = v_rec.customer_id;
	END LOOP;
END;
-- 0.062 sec => 0.05 sec
DECLARE
	CURSOR cur_update 
    IS SELECT * FROM customers 
    WHERE credit_limit < 5000 FOR UPDATE;
BEGIN
	FOR v_rec IN cur_update
	LOOP
			UPDATE customers 
			SET credit_limit = credit_limit + 200
			WHERE CURRENT OF cur_update;
	END LOOP;
END;

-- // task 4
/*
—оздайте спецификацию пакета, который определ€ет подтипы,
допустимые дл€ пол€ warranty_period таблицы product information 
ƒайте им€ пакету MY_TYPES.
“ип должен позвол€ть хранить информацию о количестве лет и мес€цев,
составл€ющих гарантийный срок.
*/
CREATE or REPLACE PACKAGE my_types
IS
    TYPE type_v_warranty_period IS RECORD (mm POSITIVE,yyyy POSITIVE);
    SUBTYPE v_warranrty_period IS type_v_warranty_period;
END my_types;

--//task 5
/*
—оздайте пакет с именем SHOW_DETAILS, который включает две подпрограммы. 
ѕерва€ подпрограмма должна отображать сведени€ о заказе по идентификатору заказа.
¬тора€ подпрограмма должна отображать подробные сведени€:
ID, им€, телефоны, лимит кредита, электронные адреса, о покупателе с заданным идентификатром.
ќбе программы должны передавать требуемые данные через курсорные переменные.
*/
CREATE or REPLACE PACKAGE show_details
IS
    TYPE cur_one_order IS REF CURSOR RETURN orders%ROWTYPE;
    
    TYPE info_cust IS RECORD (cust_id NUMBER(6,0), cust_name VARCHAR2(20), cust_lim_credit NUMBER(9,2), cust_email VARCHAR(40));
    TYPE cur_info_cust IS REF CURSOR RETURN info_cust; 
    
    PROCEDURE show_oreder (p_order_id IN NUMBER, p_ret_order OUT cur_one_order);
    PROCEDURE show_info_cust (p_cust_id IN NUMBER, p_ret_info_cust OUT cur_info_cust);
END show_details;

CREATE OR REPLACE PACKAGE BODY show_details
AS

    PROCEDURE show_oreder (p_order_id IN NUMBER, p_ret_order OUT cur_one_order)
    IS
    BEGIN
        OPEN p_ret_order
            FOR SELECT * FROM orders
                WHERE order_id = p_order_id;
    END show_oreder;
    
    PROCEDURE show_info_cust (p_cust_id IN NUMBER, p_ret_info_cust OUT cur_info_cust)
    IS
    BEGIN
        OPEN p_ret_info_cust
            FOR SELECT CUSTOMER_ID, CUST_FIRST_NAME, CREDIT_LIMIT, CUST_EMAIL 
                FROM customers
                WHERE CUSTOMER_ID = p_cust_id;
    END show_info_cust;

END;

DECLARE
    cur_tmp show_details.cur_info_cust;
    tmp show_details.info_cust;
BEGIN    
    show_details.show_info_cust(144,cur_tmp);
    FETCH cur_tmp INTO tmp;
        DBMS_OUTPUT.PUT_LINE (tmp.cust_name);
    CLOSE cur_tmp;
    
END;