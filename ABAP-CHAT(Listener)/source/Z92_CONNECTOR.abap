Data: message type string.

class lcl_amc_test_text definition
FINAL
create public .

  public section.
    interfaces if_amc_message_receiver_text .
endclass.

class lcl_amc_test_text implementation.
  method if_amc_message_receiver_text~receive.
    message = i_message.
    return.
  endmethod.
endclass.

FUNCTION Z92_CONNECTOR.
*"----------------------------------------------------------------------
*"*"Локальный интерфейс:
*"  IMPORTING
*"     VALUE(IN_TEST) TYPE  STRING OPTIONAL
*"  EXPORTING
*"     VALUE(OUT_TEST) TYPE  STRING
*"----------------------------------------------------------------------
  OUT_TEST = IN_TEST.

**** слушатель

  data: lo_consumer      type ref to if_amc_message_consumer.


  DATA: lo_receiver_text TYPE REF TO lcl_amc_test_text,
        lx_amc_error     TYPE REF TO cx_amc_error.

  TRY.
      lo_consumer = cl_amc_channel_manager=>create_message_consumer( i_application_id = 'Z_CHANNEL_TEST' i_channel_id = '/teleport' ).
      lo_receiver_text = new #( ).

      lo_consumer->start_message_delivery( lo_receiver_text ).

      wait for messaging channels until message is not initial up to 1000 seconds.

    CATCH cx_amc_error INTO lx_amc_error.
      MESSAGE lx_amc_error->get_text( ) TYPE 'E'.
      OUT_TEST = lx_amc_error->get_text( ).
      exit.
  ENDTRY.
  OUT_TEST = message.



ENDFUNCTION.