/*
От имени пользователя SYS создайте новое табличное пространство для хранения данных LOB.
*/

CREATE TABLESPACE lob_tbs2
  DATAFILE 'lob_tbs2.dbf' SIZE 1500M REUSE
  AUTOEXTEND ON NEXT 200M
  MAXSIZE 3000M
  SEGMENT SPACE MANAGEMENT AUTO;

/*
Создайте объект DIRECTORY, ссылающийся на расположение файлов LOB (D:\labs\DATA_FILES\PRODUCT_PIC).
Предоставьте пользователю OE привилегию на чтение данных из объекта DIRECTORY. 
*/

CREATE OR REPLACE DIRECTORY product_files 
  AS 'C:\PRODUCT_PIC';

GRANT READ ON DIRECTORY product_files TO oe;

/*
Подключившись  к БД как SYSTEM проверьте тип сегмента в словаре данных. 
*/

SELECT segment_name, segment_type, segment_subtype 
FROM   dba_segments 
WHERE  tablespace_name = 'LOB_TBS2'
AND    segment_type = 'LOBSEGMENT';

/*
Подключитесь к БД как пользователь SYSTEM и выполните скрипт,
реализующий «переопределение в реальном времени». 
*/

DECLARE
 error_count PLS_INTEGER := 0;
BEGIN
  DBMS_REDEFINITION.START_REDEF_TABLE
    ('OE', 'product_descriptions', 'product_descriptions_interim',
     'product_id product_id, detailed_product_info detailed_product_info',
      OPTIONS_FLAG => DBMS_REDEFINITION.CONS_USE_ROWID);
  DBMS_REDEFINITION.COPY_TABLE_DEPENDENTS
    ('OE', 'product_descriptions', 'product_descriptions_interim', 
      1, true,true,true,false, error_count);
  DBMS_OUTPUT.PUT_LINE('Errors := ' || TO_CHAR(error_count));
  DBMS_REDEFINITION.FINISH_REDEF_TABLE
    ('OE', 'product_descriptions', 'product_descriptions_interim');
END;

/*
Подключившись как пользователь SYSTEM, проверьте,
обратившись к словарю данных, формат хранения LOB в сегменте.
*/

SELECT segment_name, segment_type, segment_subtype 
FROM dba_segments 
WHERE tablespace_name = 'LOB_TBS2'
AND segment_type = 'LOBSEGMENT';

