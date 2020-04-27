*&---------------------------------------------------------------------*
*& Report Z92_CHAT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z92_CHAT.

types: begin of tab_s,
         timeMes  type sy-uzeit,
         uname    type sy-uname,
         messages type string,
         color(4),
       end of tab_s.

data: tab          type table of tab_s,

      grid         type ref to cl_gui_alv_grid,
      container    type ref to cl_gui_custom_container,
      f_catalog    type lvc_t_fcat,
      layout       type lvc_s_layo,

      USER_MESSAGE type string,

      taskname     type string.


load-of-program.
  perform creaty_f_catalog.


start-of-selection.

*********   отправитель
  data: lo_producer_text type ref to if_amc_message_producer_text.
  lo_producer_text ?= cl_amc_channel_manager=>create_message_producer( i_application_id = 'Z_CHANNEL_TEST' i_channel_id = '/teleport' ).

***************

* запускаем слушатель в отдельном "треде"
  taskname = 'CONNECTOR_' && sy-uname && sy-uzeit.
  call function 'Z92_CONNECTOR'
    starting new task taskname
    performing give_fm_data on end of task
    exceptions
      communication_failure = 1
      system_failure        = 2.
*
*
  call screen 100.



*&---------------------------------------------------------------------*
*&      Form  CREATY_F_CATALOG
*&---------------------------------------------------------------------*
FORM CREATY_F_CATALOG .

  perform new_field using '1'  'Время'        'TIMEMES'  'TIMS' 15  15  '' '' '' 'CHAR'  '' '' changing f_catalog.
  perform new_field using '2'  'Пользователь' 'UNAME'    'CHAR' 15  15  '' '' '' 'CHAR'  '' '' changing f_catalog.
  perform new_field using '3'  'Сообщение'    'messages' 'CHAR' 150 150 '' '' '' 'CHAR'  '' '' changing f_catalog.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NEW_FIELD
*&---------------------------------------------------------------------*
FORM NEW_FIELD  USING  p_num
                       p_nam
                       p_field
                       p_type
                       p_len
                       p_outlen
                       p_key
                       p_edit
                       p_f4
                       p_rfield
                       p_conv
                       p_sum
              changing p_f_catalog type lvc_t_fcat.

  DATA fcat_property TYPE lvc_s_fcat.
  fcat_property-col_pos = p_num.
  fcat_property-fieldname = p_field.
  fcat_property-key = p_key.
  fcat_property-outputlen = p_outlen.
  fcat_property-datatype = p_type.
  fcat_property-intlen = p_len.
  fcat_property-reptext = p_nam.
  fcat_property-scrtext_l = p_nam.
  fcat_property-scrtext_m = p_nam.
  fcat_property-scrtext_s = p_nam.
  fcat_property-just = 'X'.
  fcat_property-edit = p_edit.
  fcat_property-f4availabl = p_f4.
  fcat_property-ref_field = p_rfield.
  fcat_property-do_sum = p_sum.
  fcat_property-LOWERCASE = 'X'.
  APPEND fcat_property TO p_f_catalog.

ENDFORM.

INCLUDE z92_chat_status_0100o01.
*&---------------------------------------------------------------------*
*&      Form  REFRESH_GRID
*&---------------------------------------------------------------------*
FORM REFRESH_GRID .

  data ls_stable type lvc_s_stbl.
  ls_stable-row = abap_true.
  ls_stable-col = abap_true.

  grid->refresh_table_display( exporting is_stable = ls_stable ).

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GIVE_FM_DATA
*&---------------------------------------------------------------------*
FORM GIVE_FM_DATA  using taskname.

  data: fm_message type string.

  receive results from function 'Z92_CONNECTOR'
  importing
    out_test = fm_message.

  if fm_message is not initial.

    data: tab_line type tab_s.

    get time.
    tab_line-timemes = sy-uzeit.


    split fm_message at '@' into tab_line-uname tab_line-messages.

    append tab_line to tab.
  endif.

  if lines( tab ) > 25.
    data end_i type i.
    end_i = lines( tab ) - 25.
    delete tab from 1 to end_i.

  endif.

  set user-command 'OKCD'.

ENDFORM.