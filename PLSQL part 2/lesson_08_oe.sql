/*
������������� � �� ��� ������������ OE, ������� ������������ ������� 
PRODUCT_DESCRIPTIONS � �������� �����:
*/

DROP TABLE product_descriptions; 

CREATE TABLE product_descriptions 
  (product_id NUMBER);

/*
�� ����� ������������ OE �������� ����� �������,
������� � ��� ������� ���� BLOB � ������� BASICFILE.
*/

ALTER TABLE product_descriptions ADD
 (detailed_product_info BLOB )
  LOB (detailed_product_info) STORE AS BASICFILE (tablespace lob_tbs2);

/*
�������� ��������� ��� �������� ������ � ���������� LOB: 
*/

CREATE OR REPLACE PROCEDURE loadLOBFromBFILE_proc (
  p_dest_loc IN OUT BLOB, p_file_name IN VARCHAR2)
IS
  v_src_loc  BFILE := BFILENAME('PRODUCT_FILES', p_file_name);
  v_amount   INTEGER := 4000;
BEGIN
  DBMS_LOB.OPEN(v_src_loc, DBMS_LOB.LOB_READONLY);
  v_amount := DBMS_LOB.GETLENGTH(v_src_loc);
  DBMS_LOB.LOADFROMFILE(p_dest_loc, v_src_loc, v_amount);
  DBMS_LOB.CLOSE(v_src_loc);
END loadLOBFromBFILE_proc;

/*  
�� ����� ������������ OE �������� ��������� ��� ������� ������ LOB � �������: 
*/

CREATE OR REPLACE PROCEDURE write_lob (p_file IN VARCHAR2)
IS
  i    NUMBER;   v_id NUMBER;  v_b  BLOB;
BEGIN
  DBMS_OUTPUT.ENABLE;
  DBMS_OUTPUT.PUT_LINE('Begin inserting rows...');
  FOR i IN 1 .. 5 LOOP
    v_id:=SUBSTR(p_file, 1, 4);
    INSERT INTO product_descriptions 
      VALUES (v_id, EMPTY_BLOB())
      RETURNING detailed_product_info INTO v_b;
    loadLOBFromBFILE_proc(v_b,p_file);
    DBMS_OUTPUT.PUT_LINE('Row '|| i ||' inserted.');
  END LOOP;
  COMMIT;
END write_lob;

/*
��������� �������� ������ � ������� ��������� ���������.
��� ������������� SQL*Plus, ����� ��������������� ��������� ��� ������ ������� ���������� 
*/

set serveroutput on
set verify on
set term on
set lines 200
timing start load_data 
execute write_lob('1726_LCD.doc');
execute write_lob('1734_RS232.doc');
execute write_lob('1739_SDRAM.doc');
timing stop

/*
����� ������������� � �� ��� ������������ OE, �������� ����� ��������� �������
� ����� �������� �������� ������ LOB. 
*/

CREATE TABLE product_descriptions_interim 
(product_id NUMBER,
 detailed_product_info BLOB)
 LOB(detailed_product_info) STORE AS SECUREFILE
 (TABLESPACE lob_tbs2);

/*
�������������, ��� ������������ OE ������� ��������� �������.
*/

DROP TABLE product_descriptions_interim;

/*
������������ � �� ��� ������������ OE � ������� �����, ���������� ��������,
� ������� ��������� CHECK_SPACE .
*/

CREATE OR REPLACE PROCEDURE check_space 
IS
  l_fs1_bytes NUMBER;
  l_fs2_bytes NUMBER;
  l_fs3_bytes NUMBER;
  l_fs4_bytes NUMBER;
  l_fs1_blocks NUMBER;
  l_fs2_blocks NUMBER;
  l_fs3_blocks NUMBER;
  l_fs4_blocks NUMBER;
  l_full_bytes NUMBER;
  l_full_blocks NUMBER;
  l_unformatted_bytes NUMBER;
  l_unformatted_blocks NUMBER;
BEGIN 
  DBMS_SPACE.SPACE_USAGE( 
    segment_owner      => 'OE',
    segment_name       => 'PRODUCT_DESCRIPTIONS', 
    segment_type       => 'TABLE', 
    fs1_bytes          => l_fs1_bytes,
    fs1_blocks         => l_fs1_blocks, 
    fs2_bytes          => l_fs2_bytes,
    fs2_blocks         => l_fs2_blocks, 
    fs3_bytes          => l_fs3_bytes,
    fs3_blocks         => l_fs3_blocks,
    fs4_bytes          => l_fs4_bytes,
    fs4_blocks         => l_fs4_blocks,
    full_bytes         => l_full_bytes,
    full_blocks        => l_full_blocks,
    unformatted_blocks => l_unformatted_blocks,
    unformatted_bytes  => l_unformatted_bytes 
   );
DBMS_OUTPUT.ENABLE;
  DBMS_OUTPUT.PUT_LINE(' FS1 Blocks = '||l_fs1_blocks||'
     Bytes = '||l_fs1_bytes);
  DBMS_OUTPUT.PUT_LINE(' FS2 Blocks = '||l_fs2_blocks||' 
     Bytes = '||l_fs2_bytes);
  DBMS_OUTPUT.PUT_LINE(' FS3 Blocks = '||l_fs3_blocks||' 
     Bytes = '||l_fs3_bytes);
  DBMS_OUTPUT.PUT_LINE(' FS4 Blocks = '||l_fs4_blocks||' 
     Bytes = '||l_fs4_bytes);
  DBMS_OUTPUT.PUT_LINE('Full Blocks = '||l_full_blocks||' 
     Bytes = '||l_full_bytes);
  DBMS_OUTPUT.PUT_LINE('====================================
      =========');
DBMS_OUTPUT.PUT_LINE('Total Blocks = 
     '||to_char(l_fs1_blocks + l_fs2_blocks +
     l_fs3_blocks + l_fs4_blocks + l_full_blocks)||  ' ||  
     Total Bytes = '|| to_char(l_fs1_bytes + l_fs2_bytes 
     + l_fs3_bytes + l_fs4_bytes + l_full_bytes));
END;

set serveroutput on
execute check_space;
