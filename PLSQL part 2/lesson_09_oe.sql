set serveroutput on;

EXECUTE credit_card_pkg.update_card_info(144, 'MC', 2323232323);
EXECUTE credit_card_pkg.update_card_info(144, 'DC', 4444444);
EXECUTE credit_card_pkg.update_card_info(144, 'AM EX', 55555555555);
/*
PL/SQL procedure successfully completed
*/
 
EXECUTE credit_card_pkg.display_card_info(144);
/*
Card Type: Visa / Card No: 11111111
Card Type: MC / Card No: 2323232323
Card Type: DC / Card No: 4444444
Card Type: AM EX / Card No: 55555555555
*/

/*
Далее требуется изменить процедуру UPDATE_CARD_INFO таким образом,
чтобы она возвращала информацию об измененных кредитных картах
(используя фразу RETURNING).

a.Исправьте код, добавив в него фразу RETURNING, возвращающую информацию о
строках, измененных командой UPDATE.
*/
CREATE OR REPLACE PACKAGE credit_card_pkg
IS
  FUNCTION cust_card_info 
    (p_cust_id NUMBER, p_card_info IN OUT typ_cr_card_nst )
    RETURN BOOLEAN;
  
  PROCEDURE update_card_info
    (p_cust_id NUMBER, p_card_type VARCHAR2, 
     p_card_no VARCHAR2, o_card_info OUT typ_cr_card_nst);
  
  PROCEDURE display_card_info
    (p_cust_id NUMBER);

END credit_card_pkg;  -- package spec

CREATE OR REPLACE PACKAGE BODY credit_card_pkg
IS

  FUNCTION cust_card_info 
    (p_cust_id NUMBER, p_card_info IN OUT typ_cr_card_nst )
    RETURN BOOLEAN
  IS
    v_card_info_exists BOOLEAN;
  BEGIN
    SELECT credit_cards
      INTO p_card_info
      FROM customers
      WHERE customer_id = p_cust_id;
    IF p_card_info.EXISTS(1) THEN
      v_card_info_exists := TRUE;
    ELSE
      v_card_info_exists := FALSE;
    END IF;

    RETURN v_card_info_exists;

  END cust_card_info;

  PROCEDURE update_card_info
    (p_cust_id NUMBER, p_card_type VARCHAR2, 
     p_card_no VARCHAR2, o_card_info OUT typ_cr_card_nst)
  IS
    v_card_info typ_cr_card_nst;
    i PLS_INTEGER;
  BEGIN
    
    IF cust_card_info(p_cust_id, v_card_info) THEN  -- cards exist, add more
      i := v_card_info.LAST;
      v_card_info.EXTEND(1);
      v_card_info(i+1) := typ_cr_card(p_card_type, p_card_no);
      UPDATE customers
        SET  credit_cards = v_card_info
        WHERE customer_id = p_cust_id
        RETURNING credit_cards INTO o_card_info;
    ELSE   -- no cards for this customer yet, construct one
      UPDATE customers
        SET  credit_cards = typ_cr_card_nst
            (typ_cr_card(p_card_type, p_card_no))
        WHERE customer_id = p_cust_id
        RETURNING credit_cards INTO o_card_info;
    END IF;
  END update_card_info;


  PROCEDURE display_card_info
    (p_cust_id NUMBER)
  IS
    v_card_info typ_cr_card_nst;
    i PLS_INTEGER;
  BEGIN
    IF cust_card_info(p_cust_id, v_card_info) THEN
      FOR idx IN v_card_info.FIRST..v_card_info.LAST LOOP
          DBMS_OUTPUT.PUT('Card Type: ' || v_card_info(idx).card_type || ' ');
        DBMS_OUTPUT.PUT_LINE('/ Card No: ' || v_card_info(idx).card_num );
      END LOOP;
    ELSE
      DBMS_OUTPUT.PUT_LINE('Customer has no credit cards.');
    END IF;
  END display_card_info;  
END credit_card_pkg;  -- package body

/*
b.	Для проверки внесенных изменений создайте процедуру:
*/

CREATE OR REPLACE PROCEDURE test_credit_update_info 
(p_cust_id NUMBER, p_card_type VARCHAR2, p_card_no NUMBER)
IS
  v_card_info typ_cr_card_nst;
BEGIN
  credit_card_pkg.update_card_info 
    (p_cust_id, p_card_type, p_card_no, v_card_info);
END test_credit_update_info;

EXECUTE test_credit_update_info(145, 'AM EX', 123456789);

SELECT credit_cards FROM customers WHERE customer_id = 125;

/*
5.	Далее попробуем использовать конструкцию SAVE EXCEPTIONS.
a.	Создайте следующую таблицу:
*/

CREATE TABLE card_table 
(accepted_cards VARCHAR2(50) NOT NULL);

/*
Выполните следующий блок:
*/
DECLARE
  type typ_cards is table of VARCHAR2(50);
  v_cards typ_cards := typ_cards 
  ( 'Citigroup Visa', 'Nationscard MasterCard', 
    'Federal American Express', 'Citizens Visa', 
    'International Discoverer', 'United Diners Club' );
BEGIN
  v_cards.Delete(3);
  v_cards.DELETE(6);
  FORALL j IN v_cards.first..v_cards.last 
    SAVE EXCEPTIONS
    EXECUTE IMMEDIATE
   'insert into card_table (accepted_cards) values ( :the_card)'
    USING v_cards(j);
END;

/*
b.	Выполните следующий блок:
*/

DECLARE
  type typ_cards is table of VARCHAR2(50);
  v_cards typ_cards := typ_cards 
  ( 'Citigroup Visa', 'Nationscard MasterCard', 
    'Federal American Express', 'Citizens Visa', 
    'International Discoverer', 'United Diners Club' );
  bulk_errors EXCEPTION;
  PRAGMA exception_init (bulk_errors, -24381 );
BEGIN
  v_cards.Delete(3);
  v_cards.DELETE(6);
  FORALL j IN v_cards.first..v_cards.last 
    SAVE EXCEPTIONS
    EXECUTE IMMEDIATE
   'insert into card_table (accepted_cards) values ( :the_card)'
    USING v_cards(j);
 EXCEPTION
  WHEN  bulk_errors THEN
    FOR j IN 1..sql%bulk_exceptions.count
  LOOP
    Dbms_Output.Put_Line ( 
      TO_CHAR( sql%bulk_exceptions(j).error_index ) || ':
      ' || SQLERRM(-sql%bulk_exceptions(j).error_code) );
  END LOOP;
END;

/*
6.	Сравним разницу в производительности программ,
использующих типы данных PLS_INTEGER, SIMPLE_INTEGER и «нативную» компиляцию:
a.	Создайте процедуру с условной компиляцией:
*/

CREATE OR REPLACE PROCEDURE p 
IS
  t0       NUMBER :=0;  
  t1       NUMBER :=0;

 $IF $$Simple $THEN
  SUBTYPE My_Integer_t IS                     SIMPLE_INTEGER;
  My_Integer_t_Name CONSTANT VARCHAR2(30) := 'SIMPLE_INTEGER';
 $ELSE
  SUBTYPE My_Integer_t IS                     PLS_INTEGER;
  My_Integer_t_Name CONSTANT VARCHAR2(30) := 'PLS_INTEGER';
 $END

 v00  My_Integer_t := 0;     v01  My_Integer_t := 0;
 v02  My_Integer_t := 0;     v03  My_Integer_t := 0;
 v04  My_Integer_t := 0;     v05  My_Integer_t := 0;

 two      CONSTANT My_Integer_t := 2;
 lmt      CONSTANT My_Integer_t := 100000000;

BEGIN
  t0 := DBMS_UTILITY.GET_CPU_TIME();
  WHILE v01 < lmt LOOP
    v00 := v00 + Two;     
    v01 := v01 + Two;
    v02 := v02 + Two;    
    v03 := v03 + Two;
    v04 := v04 + Two;     
    v05 := v05 + Two;
  END LOOP;

  IF v01 <> lmt OR v01 IS NULL THEN
    RAISE Program_Error;
  END IF;

  t1 := DBMS_UTILITY.GET_CPU_TIME();
  DBMS_OUTPUT.PUT_LINE(
    RPAD(LOWER($$PLSQL_Code_Type), 15)||
    RPAD(LOWER(My_Integer_t_Name), 15)||
    TO_CHAR((t1-t0), '9999')||' centiseconds');
END p;


ALTER PROCEDURE p COMPILE
PLSQL_Code_Type = NATIVE PLSQL_CCFlags = 'simple:true'
REUSE SETTINGS;

EXECUTE p();

ALTER PROCEDURE p COMPILE
PLSQL_Code_Type = native PLSQL_CCFlags = 'simple:false'
REUSE SETTINGS;

EXECUTE p();

/*
Так как simple_integer является подтипом pls_integer,
он наследует его свойства как 32-битного целого числа со знаком и
может быть целым числом от отрицательного -2,147,483,648 до
положительного 2,147,483,647 значений. Однако он отличается от pls_integer
следующим: этот тип не допускает значения null, но допускает переполнение,
то есть когда значение превышает максимум, оно сбрасывается, но ошибка не появляется.
*/