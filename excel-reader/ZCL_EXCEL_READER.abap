class ZCL_EXCEL_READER definition
  public
  create public .

public section.

  methods CONSTRUCTOR
    importing
      value(EXCEL_BIN) type XSTRING optional .
  methods READ_EXCEL
    exporting
      value(E_FILE_NAME_PATH) type STRING
    returning
      value(R_STATUS) type CHAR1 .
  methods SET_EXCEL_BIN
    importing
      value(I_EXCEL_BIN) type XSTRING .
  methods PREPARE
    importing
      value(I_SHEET_NUMBER) type I default 1 .
  methods GET_TABLE
    importing
      value(I_HANDLE_ROWS) type I default 1
    exporting
      value(E_TABLE) type STANDARD TABLE .
  methods GET_EXCEL_BIN
    returning
      value(R_EXCEL_BIN) type XSTRING .
  methods GET_SHEETS
    exporting
      value(E_SHEETS) type STANDARD TABLE .
  class-methods ITAB_TO_XLSX
    importing
      !IT_FIELDCAT type LVC_T_FCAT optional
      !IT_SORT type LVC_T_SORT optional
      !IT_FILT type LVC_T_FILT optional
      !IS_LAYOUT type LVC_S_LAYO optional
      !IT_HYPERLINKS type LVC_T_HYPE optional
      value(IT_DATA) type STANDARD TABLE
    returning
      value(R_XSTRING) type XSTRING .
  protected section.
  private section.

    types:
      T_WORKSHEET_NAMES type standard table of string .
    types:
      begin of CONVERT_MAPPING,
        index     type int4,
        name      type string,
        type_kind type char1,
      end of CONVERT_MAPPING .

    data EXCEL_BIN type XSTRING .
    data SHEETS type T_WORKSHEET_NAMES .
    data RAW_ITAB type ref to DATA .
ENDCLASS.



CLASS ZCL_EXCEL_READER IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] EXCEL_BIN                      TYPE        XSTRING(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method CONSTRUCTOR.

    me->excel_bin = excel_bin.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->GET_EXCEL_BIN
* +-------------------------------------------------------------------------------------------------+
* | [<-()] R_EXCEL_BIN                    TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_EXCEL_BIN.

    r_excel_bin = me->excel_bin.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->GET_SHEETS
* +-------------------------------------------------------------------------------------------------+
* | [<---] E_SHEETS                       TYPE        STANDARD TABLE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_SHEETS.

    e_sheets = sheets.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->GET_TABLE
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_HANDLE_ROWS                  TYPE        I (default =1)
* | [<---] E_TABLE                        TYPE        STANDARD TABLE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method GET_TABLE.

    check me->raw_itab is not initial.

    field-symbols: <tab> type standard table.
    assign me->raw_itab->* to <tab>.

    if i_handle_rows > 0.
      delete <tab> from 1 to i_handle_rows. " обрезаем заголовок
    endif.
*****************************************************
    try .

        data: output_tabledescr type ref to cl_abap_tabledescr.
        output_tabledescr ?= cl_abap_tabledescr=>describe_by_data( E_TABLE ).

        data: output_structdescr type ref to cl_abap_structdescr.
        output_structdescr ?= output_tabledescr->get_table_line_type( ).
        DATA(output_components) = output_structdescr->get_components( ).

        data: excel_structdescr type ref to cl_abap_structdescr.
        excel_structdescr ?= cl_abap_structdescr=>describe_by_data( <tab>[ 1 ] ).
        data(excel_components) = excel_structdescr->get_components( ).

        data: mapping_table type standard table of convert_mapping.

* генерируем строку соотвествующую названию полей нашей структуры
        insert initial line into <tab> index 1.
        assign <tab>[ 1 ] to field-symbol(<row>).
        if <row> is assigned.

          loop at excel_components into data(src_comp).

            data(my_index) = sy-tabix.

            if line_exists( output_components[ my_index ] ). " тут же обрезаются лишние столбцы в EXCEL
              data(output_comp) = output_components[ my_index ].

              assign component src_comp-name of structure <row> to field-symbol(<row_header_field>).
              <row_header_field> = output_comp-name.

**************************** создаем мапинг строки для последующей конвертации
              append initial line to mapping_table assigning field-symbol(<mapping>).
              <mapping>-index = my_index.
              <mapping>-name = output_comp-name.
              <mapping>-type_kind = output_comp-type->type_kind.
            endif.
          endloop.
        endif.


        delete <tab>  index 1.
        loop at <tab> assigning field-symbol(<excel_row>).
          data(tabix) = sy-tabix.

          append initial line to e_table assigning field-symbol(<output_row>).

          loop at mapping_table into data(mapping).

            assign component mapping-index of structure <excel_row> to field-symbol(<excel_cell>).
            assign component mapping-index of structure <output_row> to field-symbol(<output_column_fld>).

******** обработка полей
            try .
                if mapping-type_kind = 'D'.
                  replace all occurrences of '-' in <excel_cell> with ''.
                endif.
                if mapping-type_kind = 'N'.
                  replace all occurrences of '.' in <excel_cell> with ''.
                endif.
              catch cx_root.
                clear <excel_cell>.
            endtry.

******** присваивание
            try.
                <output_column_fld> = <excel_cell>.
              catch cx_root.
                clear: <output_column_fld>.
            endtry.

          endloop.
        endloop.
      catch cx_root.
    endtry.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method ZCL_EXCEL_READER=>ITAB_TO_XLSX
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_FIELDCAT                    TYPE        LVC_T_FCAT(optional)
* | [--->] IT_SORT                        TYPE        LVC_T_SORT(optional)
* | [--->] IT_FILT                        TYPE        LVC_T_FILT(optional)
* | [--->] IS_LAYOUT                      TYPE        LVC_S_LAYO(optional)
* | [--->] IT_HYPERLINKS                  TYPE        LVC_T_HYPE(optional)
* | [--->] IT_DATA                        TYPE        STANDARD TABLE
* | [<-()] R_XSTRING                      TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method ITAB_TO_XLSX.
    data(lt_data) = ref #( it_data ).

    if it_fieldcat is initial.
      field-symbols: <tab> type standard table.
      assign lt_data->* to <tab>.
      try.
          cl_salv_table=>factory( exporting list_display = abap_false
          importing r_salv_table = data(salv_table)
          changing t_table      = <tab> ).

          data(lt_fcat) = cl_salv_controller_metadata=>get_lvc_fieldcatalog( r_columns      = salv_table->get_columns( )
                r_aggregations = salv_table->get_aggregations( ) ).
          loop at lt_fcat assigning field-symbol(<field_line>).
            <field_line>-reptext = <field_line>-fieldname.
          endloop.
        catch cx_salv_msg.
          return.
      endtry.

    else.
      lt_fcat = it_fieldcat.
    endif.

    cl_salv_bs_lex=>export_from_result_data_table( exporting is_format            = if_salv_bs_lex_format=>mc_format_xlsx
      ir_result_data_table =  cl_salv_ex_util=>factory_result_data_table(
      r_data                      = lt_data
      s_layout                    = is_layout
      t_fieldcatalog              = lt_fcat
      t_sort                      = it_sort
      t_filter                    = it_filt
      t_hyperlinks                = it_hyperlinks )
    importing er_result_file       = r_xstring ).
  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->PREPARE
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_SHEET_NUMBER                 TYPE        I (default =1)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method PREPARE.

    check me->excel_bin is not initial.

    data: mo_excel type ref to cl_fdt_xl_spreadsheet,
          sheets   type standard table of string.

    mo_excel = new #( document_name = ''
                      xdocument     = me->excel_bin ).

    mo_excel->if_fdt_doc_spreadsheet~get_worksheet_names( importing worksheet_names = me->sheets ).

    if lines( me->sheets ) >= i_sheet_number .
      data(iv_name) = me->sheets[ i_sheet_number ].
      me->raw_itab = mo_excel->if_fdt_doc_spreadsheet~get_itab_from_worksheet( iv_name ).
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->READ_EXCEL
* +-------------------------------------------------------------------------------------------------+
* | [<---] E_FILE_NAME_PATH               TYPE        STRING
* | [<-()] R_STATUS                       TYPE        CHAR1
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method READ_EXCEL.

    data: file_name type filetable,
          answer    type i.
*          fname     type string.

    types : block    type x LENGTH 1024.

    data  : data_tab type standard table of block,
            length   type i.

    cl_gui_frontend_services=>file_open_dialog( exporting window_title   = 'Выберите файл'
                                                          multiselection = abap_false
                                                 changing file_table = file_name
                                                          rc         = answer
                                               exceptions file_open_dialog_failed = 1
                                                          cntl_error              = 2
                                                          error_no_gui            = 3
                                                          not_supported_by_gui    = 4
                                                          others                  = 5 ).
    if sy-subrc <> 0 or lines( file_name ) = 0.
      R_STATUS = 'E'.
      return.
    endif.

    e_file_name_path = file_name[ 1 ].
    cl_gui_frontend_services=>gui_upload( exporting filename = e_file_name_path
                                                    filetype = 'BIN'
                                          importing filelength = length
                                           changing data_tab = data_tab
                                         exceptions file_open_error         = 1
                                                    file_read_error         = 2
                                                    no_batch                = 3
                                                    gui_refuse_filetransfer = 4
                                                    invalid_type            = 5
                                                    no_authority            = 6
                                                    unknown_error           = 7
                                                    bad_data_format         = 8
                                                    header_not_allowed      = 9
                                                    separator_not_allowed   = 10
                                                    header_too_long         = 11
                                                    unknown_dp_error        = 12
                                                    access_denied           = 13
                                                    dp_out_of_memory        = 14
                                                    disk_full               = 15
                                                    dp_timeout              = 16
                                                    not_supported_by_gui    = 17
                                                    error_no_gui            = 18
                                                    others                  = 19 ).
    if sy-subrc <> 0.
      R_STATUS = 'E'.
      return.
    else.

      concatenate lines of data_tab[] into me->excel_bin in BYTE mode.
      me->excel_bin = me->excel_bin+0(length).

      R_STATUS = 'S'.
    endif.

  endmethod.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method ZCL_EXCEL_READER->SET_EXCEL_BIN
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_EXCEL_BIN                    TYPE        XSTRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  method SET_EXCEL_BIN.

    me->excel_bin = i_excel_bin.

  endmethod.
ENDCLASS.