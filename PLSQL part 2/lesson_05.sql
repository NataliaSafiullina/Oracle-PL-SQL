-- task 1
/*
Внешняя процедура на C
*/
set serveroutput on

--GRANT EXECUTE ON c_code TO OE;

CREATE OR REPLACE LIBRARY c_code IS 'C:\WINDOWS.X64_193000_db_home\bin\mymath.dll';

create or replace
function call_c(a binary_integer, b binary_integer)
return binary_integer as language c
library c_code
name "multiply";


create or replace procedure c_output (a binary_integer, b binary_integer)
as
begin
 dbms_output.put_line(call_c (a,b));
end;

begin
 c_output (3,4);
end;

/*
connect /as sysdba

CREATE OR REPLACE LIBRARY c_code 
    AS '\WINDOWS.X64_193000_db_home\bin\mymath.dll';
/

GRANT EXECUTE ON c_code TO OE;
/

connect oe/oracle

create or replace
function call_c(a binary_integer, b binary_integer)
return binary_integer as language c
library c_code
name "multiply";
/

create or replace procedure c_output (a binary_integer, b binary_integer)
as
begin
 dbms_output.put_line(call_c (a,b));
end;
/

set serveroutput on

begin
 c_output (3,4);
end;
/

begin
*
ERROR at line 1:
ORA-28575: unable to open RPC connection to external procedure agent
ORA-06512: at "OE.CALL_C", line 1
ORA-06512: at "OE.C_OUTPUT", line 4
ORA-06512: at line 2
*/

-- task 2
/*
Внешняя процедура на Java
*/
Create Or Replace Function Sayhi
  (N String) 
  RETURN String
  AS
    Language Java
    NAME 'HelloDemo.sayHello
      (java.lang.String) return java.lang.String';

Select Sayhi ('Natalia')
From Dual;

create or replace procedure say_hello (S STRING)
as
begin
 dbms_output.put_line(Sayhi (S));
end;

begin
 say_hello ('Natalia');
end;
CREATE OR REPLACE PROCEDURE cc_format 
    (N IN OUT VARCHAR2)
    AS LANGUAGE JAVA
    NAME 'FormatCreditCardNo.formatCard(java.lang.String[])';

variable x varchar2(50);  

begin
:x := '1234567891234569';
end;

EXECUTE cc_format(:x);

print :x;