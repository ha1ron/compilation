* любая Ваша структура
  types: begin of load_str,
           field1 type string,
           field2 type int4,
           field3 type f,
           field4 type n length 10,
           field5 type dats,
         end of load_str.
 
  data: reader type ref to zcl_excel_reader,
        load  type table of load_str.
  reader = new #( ).
* откроется окошко с выбором файла
  reader->read_excel( ).
* считываем первую страницу
  reader->prepare( 1 ).
* указываем, что под заголовок у нас зарезервирована одна строка
  reader->get_table( exporting i_handle_rows = 1 importing e_table = load ).


***************************************************************************
***************************************************************************
******* 2 вариант *********************************************************
***************************************************************************
***************************************************************************

types: begin of load_str,
           field1 type string,
           field2 type int4,
           field3 type f,
           field4 type n length 10,
           field5 type dats,
         end of load_str.
 
  data: reader    type ref to zcl_excel_reader,
        load      type table of load_str,
        excel_bin type xstring.
 
*****
* инициализация excel_bin
*****
 
  reader = new #( excel_bin ).
  reader->prepare( 1 ).
* нет заголовка, значение 0
  reader->get_table( exporting i_handle_rows = 0 importing e_table = load ).