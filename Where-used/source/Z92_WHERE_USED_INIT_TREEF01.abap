*----------------------------------------------------------------------*
***INCLUDE Z92_WHERE_USED_INIT_TREEF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  INIT_TREE
*&---------------------------------------------------------------------*
MODULE INIT_TREE output.

  data: header type treemhhdr.

  if ref_tree is initial.

    header-heading = 'Объект'.
    header-width = 150.

    ref_tree = new #(
    node_selection_mode         = cl_column_tree_model=>node_sel_mode_single
    item_selection              = 'X'
    hierarchy_column_name       = 'BASE_OBJECT'
    hierarchy_header            = header ).

    perform new_col using 'LVL'                   15 'Уровень'.
    perform new_col using 'BASE_SCHEMA'           40 'Схема'.
    perform new_col using 'DEP_OBJ_TYPE' 20 'Тип объекта'.


    ref_tree->create_tree_control( parent = cl_gui_container=>screen0 ).

    perform add_nodes using ref_tree.

    perform expand_all_nodes.

  endif.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE STATUS_0100 OUTPUT.
  SET PF-STATUS 'STATUS100'.
  SET TITLEBAR 'BAR100' with object.
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
    when 'BACK'.
      leave to screen 0.
    when 'COLAPSE'.
      perform collapse_all_nodes.
    when 'EXPAND'.
      perform expand_all_nodes.
    when others.
  endcase.

ENDMODULE.