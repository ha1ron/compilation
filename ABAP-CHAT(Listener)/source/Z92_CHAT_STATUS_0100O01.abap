*----------------------------------------------------------------------*
***INCLUDE Z92_CHAT_STATUS_0100O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'STATUS100'.
  SET TITLEBAR 'BAR100'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE USER_COMMAND_0100 INPUT.
  case sy-ucomm.
    when 'OUT'.
      leave program.
    when 'ENTER'.


      data: lx_amc_error       type ref to cx_amc_error.
      try.
          data: i_message type string.

          i_message = sy-uname && '@' && USER_MESSAGE.
          lo_producer_text->send( i_message = i_message ).

        catch cx_amc_error into lx_amc_error.
          message lx_amc_error->get_text( ) type 'E'.
      endtry.
      clear: USER_MESSAGE.


    when 'OKCD'.
      perform refresh_grid.

      call function 'Z92_CONNECTOR'
        starting new task taskname
        performing give_fm_data on end of task
        exceptions
          communication_failure = 1
          system_failure        = 2.

  endcase.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  GRID_INIT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE GRID_INIT OUTPUT.

  if grid is initial.

    container = new #( 'CHAT_CONTAINER' ).

    grid = new #( container ).

    layout-zebra = abap_true.

    grid->set_table_for_first_display( exporting  is_layout = layout
                                        changing  it_outtab            = tab
                                                  it_fieldcatalog      = f_catalog ).
  endif.

  grid->register_edit_event( i_event_id = cl_gui_alv_grid=>mc_evt_modified ).

ENDMODULE.